# Record interactions with Playwright

Use the repo's Playwright fixtures and test login when available. Use a 2560×1440 desktop viewport and set the recording size explicitly to match. Use 3200×1800 when a larger source helps preserve small details and the UI looks right at that viewport. Preserve the intended layout for mobile and breakpoint-specific demos. With Playwright Test, set `use.video` to `{ mode: 'on', size: { width: 2560, height: 1440 } }` and set the matching viewport. Close the browser context before saving or reading the recording.

## Run with the repo's Playwright

Save the example as `record.mjs` in an ignored directory under the package that declares Playwright. Replace the navigation and interactions with the flow you want to show. Pass the verified dev-server URL and an output directory. Run with the repo's Node version using `mise exec -- node path/to/record.mjs <dev-url> <output-dir>`, or use `node` directly.

If the script lives outside the checkout, run it through stdin as ESM from the workspace package that provides Playwright. The bare import resolves from that workspace.

```sh
mise exec -- node --input-type=module - "$local_url" "$output_dir" < "$capture_script"
```

```js
import { resolve } from 'node:path';
import { setTimeout as hold } from 'node:timers/promises';
import { chromium } from 'playwright';

const [url, outputDir] = process.argv.slice(2);
if (!url || !outputDir) {
  throw new Error('Pass the verified local dev URL and the output directory.');
}

const viewport = { width: 2560, height: 1440 };
const browser = await chromium.launch();

try {
  const context = await browser.newContext({
    viewport,
    recordVideo: { dir: resolve(outputDir, 'raw'), size: viewport },
  });
  const page = await context.newPage();
  const video = page.video();

  try {
    await page.goto(url);
    await page.getByRole('heading', { name: 'Settings' }).waitFor();
    await hold(600);
    await page.getByRole('button', { name: 'Show details' }).click();
    await page.getByText('Details are visible').waitFor();
    await hold(1200);
  } finally {
    await context.close();
  }

  await video.saveAs(resolve(outputDir, 'show-details.webm'));
} finally {
  await browser.close();
}
```

## Run from a scratch directory

For a single file outside the repo, change the Playwright import to `import { chromium } from 'npm:playwright@latest';`. Run both commands from the same scratch directory. Deno's lockfile keeps Chromium installation and recording on the same Playwright release for that session.

```sh
# Resolve Playwright and install its matching Chromium build.
mise exec deno@latest -- deno run -A --no-config --lock=deno.lock --node-modules-dir=none npm:playwright@latest install chromium
mise exec deno@latest -- deno run -A --no-config --lock=deno.lock --node-modules-dir=none record.mjs http://127.0.0.1:3000 ./media
```

For the Node version of the same file, keep the bare `playwright` import and install it in a scratch project. Aube supplies the script's package dependency, and mise supplies Node.

```sh
# Run from a new scratch directory containing record.mjs.
printf '{"name":"ui-capture","private":true}\n' > package.json
aube add playwright@latest
aube exec playwright install chromium
mise exec node@latest -- node record.mjs http://127.0.0.1:3000 ./media
```

## Prepare the deliverable

Keep the original WebM. Use it directly if the destination supports playback and it fits the size limit. Use test auth or a preconfigured storage state to keep setup off-screen. Trim idle footage with `-ss` and `-t` and adjust the encoder's CRF before reducing dimensions. Run FFmpeg in the output directory and use fresh output names. Use H.264 for broad playback compatibility, including GitHub PRs. Use AV1 or HEVC when the destination and audience support it and the corresponding FFmpeg encoder is available.

```sh
ffmpeg -i show-details.webm -an -c:v libx264 -crf 21 -preset medium -pix_fmt yuv420p -movflags +faststart show-details-h264.mp4
ffmpeg -i show-details.webm -an -c:v libsvtav1 -crf 28 -preset 8 -pix_fmt yuv420p show-details-av1.webm
ffmpeg -i show-details.webm -an -c:v libx265 -crf 24 -preset medium -tag:v hvc1 -pix_fmt yuv420p -movflags +faststart show-details-hevc.mp4
```

If the file is still too large at an acceptable quality, export a landscape master above 1440p at 1440p first by adding `-vf scale=-2:1440` before the output filename. Use `-vf scale=-2:1080` if it still needs to be smaller. Adapt the scale for portrait. Go below 1080p only when a delivery constraint requires it or the user asks. Review the first and last frames and check text legibility at the intended playback size.

For an inline loop, use animated WebP where supported and GIF when needed. Keep either format short and start with a lower frame rate. Scale it down only as needed to meet the destination's size limit.

```sh
ffmpeg -i show-details.webm -an -vf fps=12 -c:v libwebp_anim -quality 82 -loop 0 show-details.webp
ffmpeg -i show-details.webm -filter_complex 'fps=12,split[a][b];[a]palettegen[p];[b][p]paletteuse' -loop 0 show-details.gif
```

[Playwright video documentation](https://playwright.dev/docs/videos) · [mise exec](https://mise.jdx.dev/cli/exec.html) · [Deno npm imports](https://docs.deno.com/runtime/fundamentals/node/) · [GitHub video compatibility](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files) · [FFmpeg documentation](https://ffmpeg.org/ffmpeg-all.html)
