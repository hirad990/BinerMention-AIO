import type { Metadata, Viewport } from "next";
import "./globals.css";
export const metadata:Metadata={title:"BinerMention Admin",description:"BinerMention administration console",robots:{index:false,follow:false}};
export const viewport:Viewport={width:"device-width",initialScale:1,maximumScale:1,userScalable:false,viewportFit:"cover",themeColor:"#07111f"};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="fa" dir="rtl"><body>{children}</body></html>}
