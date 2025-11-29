import React from 'react';
import { SSRProvider, Provider, defaultTheme } from '@adobe/react-spectrum';

export default function ClientApp({ Component, pageProps }: any) {
  return (
    <SSRProvider>
      <Provider theme={defaultTheme} colorScheme="light">
        <Component {...pageProps} />
      </Provider>
    </SSRProvider>
  );
}
