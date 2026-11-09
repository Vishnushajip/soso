import "@fontsource/luckiest-guy";
import "@fontsource/outfit/400.css";
import "@fontsource/outfit/600.css";
import "@fontsource/outfit/800.css";
import { continueRender, delayRender } from "remotion";

const handle = delayRender("Loading fonts");
Promise.all([
  document.fonts.load("40px 'Luckiest Guy'"),
  document.fonts.load("400 40px Outfit"),
  document.fonts.load("600 40px Outfit"),
  document.fonts.load("800 40px Outfit"),
])
  .then(() => continueRender(handle))
  .catch(() => continueRender(handle));
