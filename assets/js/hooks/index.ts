import { getNodeByItem } from "./node";
import { getItemById, setAttribute } from "./item";

export const Hooks = {
  outline: {
    selector: '.node:not([data-processed="true"]',
    mounted() {
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
