const puppeteer = require("puppeteer");

async function getSearchArgsFromItunesUrl(page, itunesUrl) {
  await page.goto(itunesUrl);
  console.error("get album name from", itunesUrl);
  return await page.evaluate(() =>
    (
      document.querySelector(".product-header__title").innerText +
      " " +
      document.querySelector(".product-header__identity").innerText
    ).split(/ /g)
  );
}

async function getSpotifyDownloadLinksFromSearchArgs(page, searchArgs) {
  console.error("Search Args:", searchArgs);

  // Perform google search
  await page.goto(
    `https://www.google.ca/search?q=${["spotify" + "album" + searchArgs].join(
      "+"
    )}`
  );

  return await page.evaluate(() => {
    return Array.from(
      document.querySelectorAll('a[href^="https://open.spotify.com/album/"]')
    ).map(a => ({
      a: a.href,
      text: a.innerText
    }));
  });
}

const formatLinkText = text => {
  let match = text.match(/(.*) by (.*) on Spotify/);
  if (match) {
    return match[2] + " - " + match[1];
  }
  return text;
};

const main = async () => {
  let searchArgs = process.argv.slice(2);
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  if (
    searchArgs.length == 1 &&
    searchArgs[0].match("https://itunes.apple.com/ca/album/")
  ) {
    searchArgs = await getSearchArgsFromItunesUrl(page, searchArgs[0]);
  }

  const albumLinks = await getSpotifyDownloadLinksFromSearchArgs(page, searchArgs);
  albumLinks.map(link => console.log(`${link.a} # ${formatLinkText(link.text)}`));
  await browser.close();
};

main();