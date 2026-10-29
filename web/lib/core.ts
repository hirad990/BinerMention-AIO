import { z } from "zod";
export const loginSchema=z.object({identity:z.string().trim().min(1,"نام کاربری یا ایمیل را وارد کن."),password:z.string().min(1,"رمز عبور الزامی است.")});
export const registerSchema=z.object({username:z.string().trim().regex(/^[a-zA-Z0-9_]{3,24}$/,"نام کاربری باید ۳ تا ۲۴ حرف انگلیسی، عدد یا _ باشد."),email:z.email("ایمیل معتبر وارد کن."),display_name:z.string().trim().max(80).optional(),password:z.string().min(10,"رمز عبور باید حداقل ۱۰ نویسه باشد.")});
export const postSchema=z.object({body:z.string().trim().min(1,"متن پست خالی است.").max(280,"حداکثر ۲۸۰ نویسه مجاز است.")});
export type Post={id:number;user_id:number;username:string;display_name?:string;avatar_url?:string|null;BlueTick?:boolean;body:string;media_url?:string|null;created_at:string;likes_count:number;reposts_count:number;replies_count:number;liked:boolean;reposted:boolean};
export type Person={id:number;username:string;display_name?:string;bio?:string;website?:string;avatar_url?:string|null;BlueTick?:boolean;followers_count?:number;following_count?:number;is_following?:boolean};
export const base=(process.env.NEXT_PUBLIC_API_BASE_URL||"https://binercraft.ir/mention-api-pub").replace(/\/$/,"");
export async function request<T>(path:string,token?:string|null,init:RequestInit={}):Promise<T>{
 let res:Response;try{res=await fetch(base+"/"+path.replace(/^\//,""),{...init,cache:"no-store",headers:{Accept:"application/json",...(init.body&&!(init.body instanceof FormData)?{"Content-Type":"application/json"}:{}),...(token?{Authorization:"Bearer "+token}:{}),...init.headers}})}catch{throw new Error("اتصال به API برقرار نشد؛ اینترنت و تنظیمات CORS را بررسی کن.")}
 const data=await res.json().catch(()=>null) as (T&{ok?:boolean;message?:string})|null;
 if(!res.ok||data?.ok===false)throw new Error(data?.message||`درخواست ناموفق بود (HTTP ${res.status}).`);
 return data as T;
}
