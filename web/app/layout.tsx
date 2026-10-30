import type { Metadata,Viewport } from "next";import "./globals.css";import Providers from "./providers";
export const metadata:Metadata={title:"BinerMention — صدای تو، دنیای تو",description:"شبکه اجتماعی BinerMention؛ پست، کاوش، استوری، پیام و ارتباط با جامعه‌ات.",applicationName:"BinerMention",openGraph:{title:"BinerMention",description:"صدای تو، دنیای تو",type:"website"}};
export const viewport:Viewport={themeColor:"#05070c",width:"device-width",initialScale:1,maximumScale:1,userScalable:false};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="fa" dir="rtl"><body><Providers>{children}</Providers></body></html>}
