import {create} from "zustand";
import {persist,createJSONStorage} from "zustand/middleware";
type Theme="dark"|"light";
type WebState={theme:Theme;setTheme:(theme:Theme)=>void;toggleTheme:()=>void};
export const useWebStore=create<WebState>()(persist((set)=>({theme:"dark",setTheme:(theme)=>set({theme}),toggleTheme:()=>set(s=>({theme:s.theme==="dark"?"light":"dark"}))}),{name:"binerm-mention-web-preferences",storage:createJSONStorage(()=>localStorage)}));
