import { createNode } from "./node";

export const Hooks = {
  outline: {
    mounted() {
      const container: HTMLElement = this.el

      container.addEventListener("keydown", (event) => {
      })

      container.addEventListener("keyup", (event) => {
      })

      this.handleEvent("insert", ({ nodes }) => {
        nodes.forEach(node => {
          const li = createNode(node)
          container.prepend(li)
        });
      })
    }
  }
}
