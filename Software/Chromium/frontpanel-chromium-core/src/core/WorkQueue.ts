/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 * Type representing a task that can be posted to a work queue.
 * A task is defined as a function that returns a promise which resolves to void.
 */
export type Task = () => Promise<void>;

/**
 * Class representing a work queue used to execute asynchronous tasks sequentially in the order they are queued.
 */
class WorkQueue {
    private _Queue = Promise.resolve();

    /**
     * Creates a new instance of WorkQueue.
     */
    constructor() {}

    /**
     * Posts an asynchronous task to the work queue. The task will be executed after all previously queued tasks have completed.
     * @param task - The task to post to the queue.
     * @returns {Promise<void>} - A promise that resolves when the task that was posted to the queue is complete.
     */
    public Post(task: Task): Promise<void> {
        const retval: Promise<void> = this._Queue.then(() => task()).catch(() => {});

        this._Queue = retval;

        return retval;
    }
}

export default WorkQueue;
