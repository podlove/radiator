import { focusin, focusout } from "./events/listener/focus";
import { input } from "./events/listener/input";
import { keydown } from "./events/listener";
import { click } from "./events/listener/click";
import {
  handleInsert,
  handleContentChange,
  handleDelete,
  handleClean,
} from "./events/handler";
import { getNodeByItem } from "./node";
import { getItemById, setAttribute } from "./item";

export const Hooks = {
  outline: {
    selector: '.item:not([data-processed="true"]',
    mounted() {
      const container: HTMLDivElement = this.el.querySelector(".nodes");

      container.addEventListener("focusin", focusin.bind(this));
      container.addEventListener("focusout", focusout.bind(this));
      container.addEventListener("input", input.bind(this));

      container.addEventListener("keydown", keydown.bind(this));
      // container.addEventListener("keyup", keyup.bind(this))

      container.addEventListener("click", click.bind(this));

      this.handleEvent("insert", handleInsert.bind(this));
      this.handleEvent("change_content", handleContentChange.bind(this));
      this.handleEvent("delete", handleDelete.bind(this));
      this.handleEvent("clean", handleClean.bind(this));

      const items = this.el.querySelectorAll(this.selector);
      items.forEach((item: HTMLDivElement) => {
        const { parent_id, prev_id } = getNodeByItem(item);
        const parentNode = getItemById(parent_id);
        const prevNode = getItemById(prev_id);

        if (prevNode) {
          prevNode.after(item);
        } else if (parentNode) {
          parentNode.querySelector(".children")!.append(item);
        }

        setAttribute(item, "processed", true);
      });
    },
  },
  updated() {
    const items = this.el.querySelectorAll(this.selector);
    items.forEach((item: HTMLDivElement) => {
      const { parent_id, prev_id } = getNodeByItem(item);
      const parentNode = getItemById(parent_id);
      const prevNode = getItemById(prev_id);

      if (prevNode) {
        prevNode.after(item);
      } else if (parentNode) {
        parentNode.querySelector(".children")!.append(item);
      }

      setAttribute(item, "processed", true);
    });
  },
};
