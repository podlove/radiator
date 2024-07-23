import { focusin, focusout } from "./events/listener/focus";
import { input } from "./events/listener/input";
import { keydown } from "./events/listener";
import { click } from "./events/listener/click";
import {
  handleList,
  handleInsert,
  handleContentChange,
  handleDelete,
  handleClean,
} from "./events/handler";

import Sortable from "../../vendor/sortable";

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLDivElement = this.el.querySelector(".children");

      container.addEventListener("focusin", focusin.bind(this));
      container.addEventListener("focusout", focusout.bind(this));
      container.addEventListener("input", input.bind(this));

      container.addEventListener("keydown", keydown.bind(this));
      // container.addEventListener("keyup", keyup.bind(this))

      container.addEventListener("click", click.bind(this));

      this.handleEvent("list", handleList.bind(this));
      this.handleEvent("insert", handleInsert.bind(this));
      this.handleEvent("change_content", handleContentChange.bind(this));
      this.handleEvent("delete", handleDelete.bind(this));
      this.handleEvent("clean", handleClean.bind(this));
    },
  },
  sortable: {
    mounted() {
      let group = this.el.dataset.group;
      let isDragging = false;
      this.el.addEventListener(
        "focusout",
        (e) => isDragging && e.stopImmediatePropagation(),
      );
      let sorter = new Sortable(this.el, {
        group: group ? { name: group, pull: true, put: true } : undefined,
        animation: 150,
        dragClass: "drag-item",
        ghostClass: "drag-ghost",
        onStart: (e) => (isDragging = true), // prevent phx-blur from firing while dragging
        onEnd: (e) => {
          isDragging = false;
          let params = {
            old: e.oldIndex,
            new: e.newIndex,
            to: e.to.dataset,
            ...e.item.dataset,
          };
          this.pushEventTo(
            this.el,
            this.el.dataset["drop"] || "reposition",
            params,
          );
        },
      });
    },
  },
  sortableInputFor: {
    mounted() {
      let group = this.el.dataset.group;
      let sorter = new Sortable(this.el, {
        group: group ? { name: group, pull: true, put: true } : undefined,
        animation: 150,
        dragClass: "drag-item",
        ghostClass: "drag-ghost",
        handle: "[data-handle]",
        forceFallback: true,
        onEnd: (e) => {
          this.el
            .closest("form")
            .querySelector("input")
            .dispatchEvent(new Event("input", { bubbles: true }));
        },
      });
    },
  },
};
