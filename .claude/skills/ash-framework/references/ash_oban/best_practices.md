# Best Practices

1. **Always define module names** - Use explicit `worker_module_name` and `scheduler_module_name` to prevent issues when refactoring.

2. **Use meaningful trigger names** - Choose clear, descriptive names for your triggers that reflect their purpose.

3. **Handle errors gracefully** - Use the `on_error` option to define how to handle records that fail processing repeatedly.

4. **Use appropriate queues** - Organize your jobs into different queues based on priority and resource requirements.

5. **Optimize read actions** - Ensure that read actions used in triggers support keyset pagination for efficient processing.

6. **Design for idempotency** - Jobs should be designed to be safely retried without causing data inconsistencies.
