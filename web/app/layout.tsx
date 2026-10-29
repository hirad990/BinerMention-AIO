import type { Metadata,Viewport } from "next";import "./globals.css";
export const metadata:Metadata={title:"BinerMention — صدای تو، دنیای تو",description:"شبکه اجتماعی BinerMention؛ پست، کاوش، پیام و ارتباط با جامعه‌ات.",applicationName:"BinerMention"};
export const viewport:Viewport={themeColor:"#05070c",width:"device-width",initialScale:1};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="fa" dir="rtl"><body>{children}</body></html>}
