# Interrupts
Let's learn about interrupts!
A fundamental concept in embedded system is the idea of an interrupt. Microcontrollers (MCU) usually have only one core and don't really allow for parallelism. This can get annoying real fast, because in order to manage multiple tasks programmers need to write complex scheduling logic (ever heard of RTOS?).

This is where interrupts come in handy. Let's say we have a n improved blinky script that toggles on and off a led every second, but we also want it to toggle a second led when a button is pressed. The simplest way is to poll at every iteration in the loop wheter the button is pressed. However this means that our microcontroller now spend most of the time checking for the button press. This is where interrupt magic comes in. We first connect a button to an interrupt pin and now, when the button is pressed, the MCU will pause what is doing, will perform a function we specify, and then will resume is course like nothing happened. Incrdible, isn't it?

In this episode we will setup an interrupt timer and external interrupt, learn about interrupt tables, Interrupt service routines, zig inline assembly, volatile pointers and the concept of MMIO.
