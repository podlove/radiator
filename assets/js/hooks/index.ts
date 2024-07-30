import { focusin, focusout } from "./events/listener/focus";
import { input } from "./events/listener/input";
import { keydown } from "./events/listener";
import {
  handleList,
  handleInsert,
  handleContentChange,
  handleDelete,
  handleClean,
} from "./events/handler";

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLDivElement = this.el.querySelector(".children");

      container.addEventListener("focusin", focusin.bind(this));
      container.addEventListener("focusout", focusout.bind(this));
      container.addEventListener("input", input.bind(this));

      container.addEventListener("keydown", keydown.bind(this));
      // container.addEventListener("keyup", keyup.bind(this))

      this.handleEvent("list", handleList.bind(this));
      this.handleEvent("insert", handleInsert.bind(this));
      this.handleEvent("change_content", handleContentChange.bind(this));
      this.handleEvent("delete", handleDelete.bind(this));
      this.handleEvent("clean", handleClean.bind(this));
    },
  },
};
