import { getNodeByItem } from "./node";
import { getItemById, setAttribute } from "./item";

export const Hooks = {
  outline: {
    selector: '.node:not([data-processed="true"]',
    mounted() {
      this.el.addEventListener("toggle_collapse", ({ detail }) => {
        const item = getItemById(detail.uuid);
        item!.toggleAttribute("data-collapsed");
        const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
        const collapsed = JSON.parse(collapsedStatus);
        collapsed[detail.uuid] = !collapsed[detail.uuid];
        localStorage.setItem(this.el.id, JSON.stringify(collapsed));
      });
      const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
      const collapsed = JSON.parse(collapsedStatus);
      const nodes = this.el.querySelectorAll(this.selector);
      nodes.forEach((item: HTMLDivElement) => {
        const { uuid, parent_id, prev_id } = getNodeByItem(item);
        const parentNode = getItemById(parent_id);
        const prevNode = getItemById(prev_id);

        if (prevNode) {
          prevNode.after(item);
        } else if (parentNode) {
          parentNode.querySelector(".children")!.append(item);
        }
        item.toggleAttribute("data-collapsed", !!collapsed[uuid]);
        setAttribute(item, "processed", true);
      });
    },
    updated() {
      const nodes = this.el.querySelectorAll(this.selector);
      nodes.forEach((item: HTMLDivElement) => {
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
};
