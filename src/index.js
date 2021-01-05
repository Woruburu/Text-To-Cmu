"use strict";

import "terminal.css";
import { Elm } from "./Main.elm";

(function () {
  const node = document.createElement("div");
  document.body.append(node);
  const app = Elm.Main.init({
    node: node,
    flags: null,
  });
})();
