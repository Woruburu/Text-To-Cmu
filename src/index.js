"use strict";

import "normalize.css";
import "terminal.css";
import ClipboardJS from "clipboard";
import "./css/index.css";
import { Elm } from "./Main.elm";

(function () {
  const node = document.createElement("div");
  document.body.append(node);
  const app = Elm.Main.init({
    node: node,
    flags: null,
  });

  new ClipboardJS("#copy-button");
})();
