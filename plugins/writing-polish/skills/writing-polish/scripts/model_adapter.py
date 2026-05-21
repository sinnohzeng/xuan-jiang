"""统一封装 Anthropic Messages API + OpenAI-compatible Chat Completions。

调用方按 role（judge / reviewer / rewriter）取适配器，配置走 default.yaml + 用户/项目 yaml +
env 兜底。所有 provider 输出折叠成纯文本 string，调用方不关心底层 API 差异。
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Literal

import yaml

Role = Literal["judge", "reviewer", "rewriter"]
ProviderType = Literal["anthropic", "openai-compatible"]

SKILL_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = SKILL_ROOT / "config" / "default.yaml"


@dataclass
class ModelConfig:
    provider: ProviderType
    model: str
    api_key: str
    base_url: str | None
    temperature: float
    max_tokens: int
    vote_rounds: int
    extra_body: dict[str, Any]


def _load_yaml(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def _deep_merge(base: dict, override: dict) -> dict:
    result = dict(base)
    for k, v in override.items():
        if isinstance(v, dict) and isinstance(result.get(k), dict):
            result[k] = _deep_merge(result[k], v)
        else:
            result[k] = v
    return result


def load_config(role: Role) -> ModelConfig:
    """配置加载优先级：env > project yaml > user yaml > default.yaml。"""
    config: dict[str, Any] = _load_yaml(DEFAULT_CONFIG)

    user_yaml = Path.home() / ".config" / "xuan-jiang" / "config.yaml"
    if user_yaml.exists():
        config = _deep_merge(config, _load_yaml(user_yaml))

    project_yaml = Path.cwd() / ".xuan-jiang.yaml"
    if project_yaml.exists():
        config = _deep_merge(config, _load_yaml(project_yaml))

    role_cfg = config.get(role, {})

    env_prefix = f"XUAN_JIANG_{role.upper()}_"
    if os.getenv(f"{env_prefix}MODEL"):
        role_cfg["model"] = os.environ[f"{env_prefix}MODEL"]
    if os.getenv(f"{env_prefix}BASE_URL"):
        role_cfg["base_url"] = os.environ[f"{env_prefix}BASE_URL"]
        role_cfg.setdefault("provider", "openai-compatible")
    if os.getenv(f"{env_prefix}API_KEY_ENV"):
        role_cfg["api_key_env"] = os.environ[f"{env_prefix}API_KEY_ENV"]
    if os.getenv(f"{env_prefix}PROVIDER"):
        role_cfg["provider"] = os.environ[f"{env_prefix}PROVIDER"]

    base_url = role_cfg.get("base_url")
    if not base_url and role_cfg.get("base_url_env"):
        base_url = os.getenv(role_cfg["base_url_env"])

    api_key_env = role_cfg.get("api_key_env", "ANTHROPIC_API_KEY")
    api_key = os.getenv(api_key_env, "")
    if not api_key:
        raise RuntimeError(
            f"Missing API key. Set env {api_key_env} or change api_key_env in config."
        )

    return ModelConfig(
        provider=role_cfg.get("provider", "anthropic"),
        model=role_cfg["model"],
        api_key=api_key,
        base_url=base_url,
        temperature=float(role_cfg.get("temperature", 0.0)),
        max_tokens=int(role_cfg.get("max_tokens", 4096)),
        vote_rounds=int(role_cfg.get("vote_rounds", 1)),
        extra_body=role_cfg.get("extra_body", {}) or {},
    )


class ModelAdapter:
    """根据 role 自动加载配置，封装两种 API 协议。"""

    def __init__(self, role: Role, config: ModelConfig | None = None) -> None:
        self.role = role
        self.config = config or load_config(role)
        self._client: Any = None

    def _client_lazy(self) -> Any:
        if self._client is not None:
            return self._client
        if self.config.provider == "anthropic":
            from anthropic import Anthropic

            self._client = Anthropic(api_key=self.config.api_key)
        elif self.config.provider == "openai-compatible":
            from openai import OpenAI

            self._client = OpenAI(
                api_key=self.config.api_key,
                base_url=self.config.base_url,
            )
        else:
            raise ValueError(f"Unknown provider: {self.config.provider}")
        return self._client

    def call(
        self,
        system: str,
        user: str,
        *,
        response_format: dict[str, Any] | None = None,
        temperature: float | None = None,
    ) -> str:
        """统一返回 plain string；Anthropic 的 content blocks 自动折叠。"""
        client = self._client_lazy()
        temperature = self.config.temperature if temperature is None else temperature

        if self.config.provider == "anthropic":
            resp = client.messages.create(
                model=self.config.model,
                max_tokens=self.config.max_tokens,
                system=system,
                messages=[{"role": "user", "content": user}],
                temperature=temperature,
            )
            return "".join(
                block.text for block in resp.content if getattr(block, "type", "") == "text"
            )

        kwargs: dict[str, Any] = {
            "model": self.config.model,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            "temperature": temperature,
            "max_tokens": self.config.max_tokens,
        }
        if response_format:
            kwargs["response_format"] = response_format
        if self.config.extra_body:
            kwargs["extra_body"] = self.config.extra_body
        resp = client.chat.completions.create(**kwargs)
        return resp.choices[0].message.content or ""

    def call_json(self, system: str, user: str) -> dict[str, Any]:
        """要求模型输出 JSON 对象。OpenAI-compatible 走 response_format，Anthropic 靠 prompt 约束。"""
        if self.config.provider == "openai-compatible":
            raw = self.call(system, user, response_format={"type": "json_object"})
        else:
            raw = self.call(system, user + "\n\n必须只输出合法 JSON 对象，不要任何解释。")
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            start = raw.find("{")
            end = raw.rfind("}")
            if start >= 0 and end > start:
                return json.loads(raw[start : end + 1])
            raise


def vote_majority(samples: list[dict[str, Any]], key: str) -> Any:
    """多次采样的多数投票（pass^k bias 校正）。"""
    if not samples:
        return None
    from collections import Counter

    values = [s.get(key) for s in samples if s.get(key) is not None]
    if not values:
        return None
    counter = Counter(map(json.dumps, values) if not all(isinstance(v, (str, int, float)) for v in values) else values)
    winner, _ = counter.most_common(1)[0]
    return winner


if __name__ == "__main__":
    import sys

    role: Role = sys.argv[1] if len(sys.argv) > 1 else "judge"
    cfg = load_config(role)
    print(f"role: {role}")
    print(f"  provider: {cfg.provider}")
    print(f"  model:    {cfg.model}")
    print(f"  base_url: {cfg.base_url or '(anthropic default)'}")
    print(f"  api key:  {'set' if cfg.api_key else 'MISSING'}")
    print(f"  temperature: {cfg.temperature}, max_tokens: {cfg.max_tokens}, vote_rounds: {cfg.vote_rounds}")
