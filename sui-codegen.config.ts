import type { SuiCodegenConfig } from "@mysten/codegen";

const config: SuiCodegenConfig = {
  output: "./ts-sdk",
  prune: true,
  packages: [
    {
      package: "@local-pkg/vault",
      path: "./contracts/vaults",
    },
  ],
};

export default config;
