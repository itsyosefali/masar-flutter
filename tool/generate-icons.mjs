// Render the source-owned vector mark; this does not alter the generated hero.
import { chromium } from '../../web/node_modules/playwright/index.mjs';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const svg = await fs.readFile(path.join(root, 'assets/brand/mark.svg'), 'utf8');
const browser = await chromium.launch({headless:true});
const page = await browser.newPage();
await page.setContent('<html><body></body></html>');
const outputs = [[48,'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'],[72,'android/app/src/main/res/mipmap-hdpi/ic_launcher.png'],[96,'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'],[144,'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'],[192,'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'],[32,'web/favicon.png'],[192,'web/icons/Icon-192.png'],[512,'web/icons/Icon-512.png'],[192,'web/icons/Icon-maskable-192.png'],[512,'web/icons/Icon-maskable-512.png']];
const contents = JSON.parse(await fs.readFile(path.join(root,'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'),'utf8'));
for (const item of contents.images) outputs.push([parseFloat(item.size)*parseFloat(item.scale), 'ios/Runner/Assets.xcassets/AppIcon.appiconset/'+item.filename]);
for (const [size, filename] of outputs) {
 const data = await page.evaluate(async ({svg,size}) => { const img=new Image(); img.src='data:image/svg+xml;base64,'+btoa(svg); await img.decode(); const c=document.createElement('canvas'); c.width=c.height=size; const ctx=c.getContext('2d'); ctx.fillStyle='#087f71'; ctx.fillRect(0,0,size,size); ctx.drawImage(img,0,0,size,size); return c.toDataURL('image/png').split(',')[1]; },{svg,size});
 await fs.writeFile(path.join(root,filename),Buffer.from(data,'base64'));
}
await browser.close();
console.log(`Rendered ${outputs.length} icons from assets/brand/mark.svg`);
