/*
  Aomi client template

  This file is a starter template for building a small TypeScript wrapper
  around the Aomi CLI or a local Aomi-backed service.

  The template is intentionally small and dependency-light so it can be copied
  into a real project and adapted quickly.
*/

import { spawnSync } from "node:child_process";

export type AomiClientOptions = {
  app?: string;
  chainId?: number;
  rpcUrl?: string;
  model?: string;
  stateDir?: string;
  publicKey?: string;
};

export type AomiRunOptions = {
  newSession?: boolean;
  verbose?: boolean;
  secrets?: Record<string, string>;
};

export type AomiResult = {
  ok: boolean;
  stdout: string;
  stderr: string;
  status: number | null;
};

export class AomiClient {
  constructor(private readonly options: AomiClientOptions = {}) {}

  private baseArgs() {
    const args: string[] = [];

    if (this.options.app) {
      args.push("--app", this.options.app);
    }

    if (this.options.chainId !== undefined) {
      args.push("--chain", String(this.options.chainId));
    }

    if (this.options.rpcUrl) {
      args.push("--rpc-url", this.options.rpcUrl);
    }

    if (this.options.model) {
      args.push("--model", this.options.model);
    }

    if (this.options.stateDir) {
      args.push("--state-dir", this.options.stateDir);
    }

    if (this.options.publicKey) {
      args.push("--public-key", this.options.publicKey);
    }

    return args;
  }

  private runCli(args: string[]): AomiResult {
    const result = spawnSync("aomi", args, {
      encoding: "utf8",
      env: process.env,
      maxBuffer: 10 * 1024 * 1024,
    });

    return {
      ok: result.status === 0,
      stdout: result.stdout ?? "",
      stderr: result.stderr ?? "",
      status: result.status,
    };
  }

  chat(prompt: string, run: AomiRunOptions = {}): AomiResult {
    const args = ["chat", prompt];

    if (run.newSession) {
      args.push("--new-session");
    }

    if (run.verbose) {
      args.push("--verbose");
    }

    for (const [name, value] of Object.entries(run.secrets ?? {})) {
      args.unshift("--secret", `${name}=${value}`);
    }

    return this.runCli([...this.baseArgs(), ...args]);
  }

  status(): AomiResult {
    return this.runCli([...this.baseArgs(), "status"]);
  }

  tx(): AomiResult {
    return this.runCli([...this.baseArgs(), "tx"]);
  }

  simulate(...txIds: string[]): AomiResult {
    return this.runCli([...this.baseArgs(), "simulate", ...txIds]);
  }

  sign(...txIds: string[]): AomiResult {
    return this.runCli([...this.baseArgs(), "sign", ...txIds]);
  }

  close(): AomiResult {
    return this.runCli([...this.baseArgs(), "close"]);
  }
}

export function createAomiClient(options: AomiClientOptions = {}) {
  return new AomiClient(options);
}

/*
Example usage:

import { createAomiClient } from "./aomi-client";

const aomi = createAomiClient({
  app: "khalani",
  chainId: 1,
  rpcUrl: process.env.RPC_URL,
  publicKey: process.env.PUBLIC_KEY,
});

const response = aomi.chat("Swap 1 ETH for USDC", {
  newSession: true,
});

console.log(response.stdout);
*/
