function testSet () {
    cpu = new DCPUCore();
    cpu.__init__();
    program = Dasm.parse("set a , 1");
    cpu.load(program);
    cpu.tick();
    assertEquals("set a, 1", cpu.registers[0], 1);
}