import React from 'react';
import dynamic from 'next/dynamic';

const ClientPage = dynamic(() => import('../components/PageWrappers/admin'), { 
  ssr: false,
  loading: () => <div style={{padding: 20}}>Loading...</div>
});

export default function Page(props: any) {
  return <ClientPage {...props} />;
}
