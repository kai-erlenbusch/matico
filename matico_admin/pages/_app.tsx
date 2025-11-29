import React from 'react';
import type { AppProps } from 'next/app';
import dynamic from 'next/dynamic';
import '../styles/globals.css';

// Dynamically import the main app logic with SSR disabled
const ClientApp = dynamic(() => import('../src/ClientApp'), { ssr: false });

function MyApp({ Component, pageProps }: AppProps) {
  // We wrap everything in the client-only component
  return <ClientApp Component={Component} pageProps={pageProps} />;
}

export default MyApp;
