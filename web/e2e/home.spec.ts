import {expect,test} from "@playwright/test";

test("renders and hydrates the BinerMention authentication screen",async({page})=>{
 const pageErrors:string[]=[];
 page.on("pageerror",error=>pageErrors.push(error.message));
 await page.goto("/mention/");
 await expect(page.getByRole("heading",{name:"BinerMention"})).toBeVisible();
 await expect(page.locator("html")).toHaveAttribute("dir","rtl");
 await page.getByRole("button",{name:"ثبت‌نام"}).click();
 await expect(page.getByPlaceholder("نام کاربری")).toBeVisible();
 await expect(page.getByPlaceholder("ایمیل")).toBeVisible();
 expect(pageErrors).toEqual([]);
});
