// Run only against the isolated local demo started by `make mobile-demo`.
import { chromium } from '../../web/node_modules/playwright/index.mjs';
import { expect } from '../../web/node_modules/@playwright/test/index.mjs';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const origin = process.env.MOBILE_PREVIEW_URL ?? 'http://127.0.0.1:8090';
const output = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../artifacts/mobile');
await fs.mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: { width: 430, height: 932 }, deviceScaleFactor: 1, permissions: ['clipboard-read', 'clipboard-write'] });
const page = await context.newPage();
page.setDefaultTimeout(15000);
const failures = [];
page.on('pageerror', error => failures.push(error.message));
async function enableSemantics() {
  await page.locator('flt-glass-pane').waitFor({ state: 'attached' });
  const placeholder = page.locator('flt-semantics-placeholder');
  if (await placeholder.count()) await placeholder.evaluate(node => node.click());
}
async function open(route) {
  await page.goto(`${origin}/#${route}`);
  await enableSemantics();
}
async function button(name) {
  await page.getByRole('button', { name, exact: true }).click();
}
async function field(name, value) {
  const input = page.getByRole('textbox', { name, exact: true });
  await input.fill(value);
  await input.press('Tab');
}
async function scrollTo(locator) {
  for (let i = 0; i < 12 && !(await locator.count()); i++) {
    await page.mouse.move(220, 550);
    await page.mouse.wheel(0, 450);
    await page.waitForTimeout(100);
  }
  await expect(locator.first()).toBeVisible();
}
async function capture(filename) {
  await page.waitForLoadState('networkidle');
  await page.mouse.move(1, 1);
  // Allow the Flutter canvas to paint decoded assets and dismiss hover tooltips.
  await page.waitForTimeout(750);
  await page.screenshot({ path: path.join(output, filename) });
}
async function screen(text) {
  await expect(page.getByText(text, { exact: false }).first()).toBeVisible();
}
try {
  const catalog = await (await page.request.get(`${origin}/api/public/offices/al-najah-demo`)).json();
  if (catalog.office?.slug !== 'al-najah-demo') throw new Error('Use the isolated demo office for this workflow.');
  await open('/');
  await screen('A smoother road ahead.');
  await capture('home-en.png');
  await page.getByRole('tab', { name: 'Services', exact: true }).click();
  await screen('Made for your next mile.');
  await capture('services-en.png');
  await page.getByRole('button', { name: /Registration renewal/ }).click();
  await button('Add to cart');
  await button('Continue to checkout');
  await screen('A little about you');
  await field('Full name', 'Flutter Browser Customer');
  await field('Phone number', '0912345678');
  await button('Continue');
  await screen('Meet your vehicle');
  await expect(page.getByRole('textbox', { name: 'Plate number', exact: true })).toHaveValue('');
  await page.getByRole('button', { name: /Municipality/ }).click();
  await page.getByRole('menuitem', { name: 'Tripoli · 5', exact: true }).click();
  await field('Plate number', `${Date.now() % 9999999 + 1}`);
  await field('Make Start typing a make…', 'Toyota');
  await field('Model Start typing a model…', 'Corolla');
  await field('Year', '2024');
  await button('Continue');
  await screen('Your documents');
  // Exercise the actual web file-picker and Go multipart validation.
  await button('Add document (0/6)');
  const chooser = page.waitForEvent('filechooser');
  await button('Choose file');
  await (await chooser).setFiles({ name: 'registration.pdf', mimeType: 'application/pdf', buffer: Buffer.from('%PDF-1.4\nFictional browser test document') });
  await expect(page.getByRole('group', { name: /registration.pdf/ })).toBeVisible();
  await button('Continue');
  await screen('Everything look right?');
  await capture('checkout-en.png');
  await button('Place order');
  await screen('You’re on your way!');
  await capture('order-en.png');
  const savedRoute = new URL(page.url()).hash;
  if (!savedRoute.startsWith('#/orders/')) throw new Error('Checkout did not navigate to the saved order');
  await page.reload();
  await enableSemantics();
  await screen('You’re on your way!');
  await scrollTo(page.locator('[aria-label*="registration.pdf"]').or(page.getByText('registration.pdf', { exact: false })));
  // A copied portal URL should also reopen the same order in a fresh context.
  await scrollTo(page.getByRole('button', { name: 'Show link', exact: true }));
  await button('Show link');
  await button('Copy private tracking link');
  const link = await page.evaluate(() => navigator.clipboard.readText());
  expect(link).toMatch(/\/portal\/\?office=al-najah-demo#track=[a-f0-9]{64}$/);
  const freshContext = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const fresh = await freshContext.newPage();
  fresh.setDefaultTimeout(15000);
  await fresh.goto(link);
  await fresh.locator('flt-glass-pane').waitFor({ state: 'attached' });
  const freshSemantics = fresh.locator('flt-semantics-placeholder');
  if (await freshSemantics.count()) await freshSemantics.evaluate(node => node.click());
  await expect(fresh.getByText('Toyota Corolla', { exact: false }).first()).toBeVisible();
  await freshContext.close();
  await button('Back to orders');
  await page.getByRole('tab', { name: 'Settings', exact: true }).click();
  await button('العربية');
  await screen('مسار على طريقتك.');
  await capture('settings-ar.png');
  await page.getByRole('tab', { name: 'الرئيسية', exact: true }).click();
  await screen('رحلة أسهل تبدأ هنا.');
  await capture('home-ar.png');
  await page.getByRole('tab', { name: 'الخدمات', exact: true }).click();
  await screen('خدمات لكل خطوة في طريقك.');
  await capture('services-ar.png');
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(`${origin}/#/`);
  await enableSemantics();
  await screen('رحلة أسهل تبدأ هنا.');
  await capture('desktop-ar.png');
  expect(failures).toEqual([]);
  console.log('Passed: catalog, checkout with document, reload recovery, tracking-link import, Arabic RTL and responsive layouts.');
  console.log(`Screenshots: ${output}`);
} catch (error) {
  await page.screenshot({ path: path.join(output, 'browser-failure.png') });
  console.error((await page.locator('body').ariaSnapshot()).slice(0, 4500));
  throw error;
} finally {
  await browser.close();
}
