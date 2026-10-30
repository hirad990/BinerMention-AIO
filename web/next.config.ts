import type { NextConfig } from "next";

const config: NextConfig = {
  // The web client is deployed below the domain root (e.g. /mention).
  // API requests remain pointed at /mention-api-pub in the app's API config.
  basePath: "/mention",
  output: "export",
  trailingSlash: true,
  images: { unoptimized: true },
  poweredByHeader: false,
};

export default config;
