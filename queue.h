#ifndef QUEUE_H
#define QUEUE_H

#include <vector>

// A first-in, first-out queue of ints (actor ids), stored in a circular buffer
struct Queue {
    std::vector<int> data;   // the buffer; its size is the capacity
    int front = 0;           // index in data of the front value
    int count = 0;           // number of values in the queue
};

// Functions you must implement in queue.cpp (Section 3)
void enqueue(Queue& q, int value);    // add at the back; grow data when full
int dequeue(Queue& q);                // remove and return the front value
bool isEmpty(const Queue& q);
void clearQueue(Queue& q);            // remove every value

#endif
