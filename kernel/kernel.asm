
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	ce478793          	addi	a5,a5,-796 # 80005d40 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e8478793          	addi	a5,a5,-380 # 80000f2a <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b70080e7          	jalr	-1168(ra) # 80000c7c <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	442080e7          	jalr	1090(ra) # 80002568 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	816080e7          	jalr	-2026(ra) # 8000094c <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	be2080e7          	jalr	-1054(ra) # 80000d30 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	ade080e7          	jalr	-1314(ra) # 80000c7c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	87c080e7          	jalr	-1924(ra) # 80001a4a <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	0d2080e7          	jalr	210(ra) # 800022b0 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	2f8080e7          	jalr	760(ra) # 80002512 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	afa080e7          	jalr	-1286(ra) # 80000d30 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ae4080e7          	jalr	-1308(ra) # 80000d30 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	5d0080e7          	jalr	1488(ra) # 80000866 <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5be080e7          	jalr	1470(ra) # 80000866 <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b2080e7          	jalr	1458(ra) # 80000866 <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	5a8080e7          	jalr	1448(ra) # 80000866 <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	99e080e7          	jalr	-1634(ra) # 80000c7c <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	2c2080e7          	jalr	706(ra) # 800025be <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a24080e7          	jalr	-1500(ra) # 80000d30 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	fe6080e7          	jalr	-26(ra) # 80002436 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	77a080e7          	jalr	1914(ra) # 80000bec <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	39c080e7          	jalr	924(ra) # 80000816 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	d2e78793          	addi	a5,a5,-722 # 800221b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b9460613          	addi	a2,a2,-1132 # 80008058 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
}


void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b6a50513          	addi	a0,a0,-1174 # 800080e0 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a68b8b93          	addi	s7,s7,-1432 # 80008058 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	672080e7          	jalr	1650(ra) # 80000c7c <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	5c2080e7          	jalr	1474(ra) # 80000d30 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <backtrace>:
{
    80000778:	7139                	addi	sp,sp,-64
    8000077a:	fc06                	sd	ra,56(sp)
    8000077c:	f822                	sd	s0,48(sp)
    8000077e:	f426                	sd	s1,40(sp)
    80000780:	f04a                	sd	s2,32(sp)
    80000782:	ec4e                	sd	s3,24(sp)
    80000784:	e852                	sd	s4,16(sp)
    80000786:	e456                	sd	s5,8(sp)
    80000788:	0080                	addi	s0,sp,64
  asm volatile("mv %0, s0" : "=r" (x));
    8000078a:	84a2                	mv	s1,s0
  printf("backtrace:\n");
    8000078c:	00008517          	auipc	a0,0x8
    80000790:	8ac50513          	addi	a0,a0,-1876 # 80008038 <etext+0x38>
    80000794:	00000097          	auipc	ra,0x0
    80000798:	dfe080e7          	jalr	-514(ra) # 80000592 <printf>
  while (PGROUNDUP(fp) - PGROUNDDOWN(fp) == PGSIZE) {
    8000079c:	6985                	lui	s3,0x1
    8000079e:	fff98a13          	addi	s4,s3,-1 # fff <_entry-0x7ffff001>
    800007a2:	797d                	lui	s2,0xfffff
    printf("%p\n", ret);
    800007a4:	00008a97          	auipc	s5,0x8
    800007a8:	8a4a8a93          	addi	s5,s5,-1884 # 80008048 <etext+0x48>
  while (PGROUNDUP(fp) - PGROUNDDOWN(fp) == PGSIZE) {
    800007ac:	014487b3          	add	a5,s1,s4
    800007b0:	0127f7b3          	and	a5,a5,s2
    800007b4:	0124f733          	and	a4,s1,s2
    800007b8:	8f99                	sub	a5,a5,a4
    800007ba:	01379c63          	bne	a5,s3,800007d2 <backtrace+0x5a>
    printf("%p\n", ret);
    800007be:	ff84b583          	ld	a1,-8(s1)
    800007c2:	8556                	mv	a0,s5
    800007c4:	00000097          	auipc	ra,0x0
    800007c8:	dce080e7          	jalr	-562(ra) # 80000592 <printf>
    fp = *(uint64 *)(fp - 16);
    800007cc:	ff04b483          	ld	s1,-16(s1)
    if (fp == 0) // 防御性检查
    800007d0:	fcf1                	bnez	s1,800007ac <backtrace+0x34>
}
    800007d2:	70e2                	ld	ra,56(sp)
    800007d4:	7442                	ld	s0,48(sp)
    800007d6:	74a2                	ld	s1,40(sp)
    800007d8:	7902                	ld	s2,32(sp)
    800007da:	69e2                	ld	s3,24(sp)
    800007dc:	6a42                	ld	s4,16(sp)
    800007de:	6aa2                	ld	s5,8(sp)
    800007e0:	6121                	addi	sp,sp,64
    800007e2:	8082                	ret

00000000800007e4 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e4:	1101                	addi	sp,sp,-32
    800007e6:	ec06                	sd	ra,24(sp)
    800007e8:	e822                	sd	s0,16(sp)
    800007ea:	e426                	sd	s1,8(sp)
    800007ec:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007ee:	00011497          	auipc	s1,0x11
    800007f2:	0ea48493          	addi	s1,s1,234 # 800118d8 <pr>
    800007f6:	00008597          	auipc	a1,0x8
    800007fa:	85a58593          	addi	a1,a1,-1958 # 80008050 <etext+0x50>
    800007fe:	8526                	mv	a0,s1
    80000800:	00000097          	auipc	ra,0x0
    80000804:	3ec080e7          	jalr	1004(ra) # 80000bec <initlock>
  pr.locking = 1;
    80000808:	4785                	li	a5,1
    8000080a:	cc9c                	sw	a5,24(s1)
}
    8000080c:	60e2                	ld	ra,24(sp)
    8000080e:	6442                	ld	s0,16(sp)
    80000810:	64a2                	ld	s1,8(sp)
    80000812:	6105                	addi	sp,sp,32
    80000814:	8082                	ret

0000000080000816 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000816:	1141                	addi	sp,sp,-16
    80000818:	e406                	sd	ra,8(sp)
    8000081a:	e022                	sd	s0,0(sp)
    8000081c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000826:	f8000713          	li	a4,-128
    8000082a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000082e:	470d                	li	a4,3
    80000830:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000834:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000838:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000083c:	469d                	li	a3,7
    8000083e:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000842:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000846:	00008597          	auipc	a1,0x8
    8000084a:	82a58593          	addi	a1,a1,-2006 # 80008070 <digits+0x18>
    8000084e:	00011517          	auipc	a0,0x11
    80000852:	0aa50513          	addi	a0,a0,170 # 800118f8 <uart_tx_lock>
    80000856:	00000097          	auipc	ra,0x0
    8000085a:	396080e7          	jalr	918(ra) # 80000bec <initlock>
}
    8000085e:	60a2                	ld	ra,8(sp)
    80000860:	6402                	ld	s0,0(sp)
    80000862:	0141                	addi	sp,sp,16
    80000864:	8082                	ret

0000000080000866 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000866:	1101                	addi	sp,sp,-32
    80000868:	ec06                	sd	ra,24(sp)
    8000086a:	e822                	sd	s0,16(sp)
    8000086c:	e426                	sd	s1,8(sp)
    8000086e:	1000                	addi	s0,sp,32
    80000870:	84aa                	mv	s1,a0
  push_off();
    80000872:	00000097          	auipc	ra,0x0
    80000876:	3be080e7          	jalr	958(ra) # 80000c30 <push_off>

  if(panicked){
    8000087a:	00008797          	auipc	a5,0x8
    8000087e:	7867a783          	lw	a5,1926(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000882:	10000737          	lui	a4,0x10000
  if(panicked){
    80000886:	c391                	beqz	a5,8000088a <uartputc_sync+0x24>
    for(;;)
    80000888:	a001                	j	80000888 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000088a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000088e:	0ff7f793          	andi	a5,a5,255
    80000892:	0207f793          	andi	a5,a5,32
    80000896:	dbf5                	beqz	a5,8000088a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000898:	0ff4f793          	andi	a5,s1,255
    8000089c:	10000737          	lui	a4,0x10000
    800008a0:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    800008a4:	00000097          	auipc	ra,0x0
    800008a8:	42c080e7          	jalr	1068(ra) # 80000cd0 <pop_off>
}
    800008ac:	60e2                	ld	ra,24(sp)
    800008ae:	6442                	ld	s0,16(sp)
    800008b0:	64a2                	ld	s1,8(sp)
    800008b2:	6105                	addi	sp,sp,32
    800008b4:	8082                	ret

00000000800008b6 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008b6:	00008797          	auipc	a5,0x8
    800008ba:	74e7a783          	lw	a5,1870(a5) # 80009004 <uart_tx_r>
    800008be:	00008717          	auipc	a4,0x8
    800008c2:	74a72703          	lw	a4,1866(a4) # 80009008 <uart_tx_w>
    800008c6:	08f70263          	beq	a4,a5,8000094a <uartstart+0x94>
{
    800008ca:	7139                	addi	sp,sp,-64
    800008cc:	fc06                	sd	ra,56(sp)
    800008ce:	f822                	sd	s0,48(sp)
    800008d0:	f426                	sd	s1,40(sp)
    800008d2:	f04a                	sd	s2,32(sp)
    800008d4:	ec4e                	sd	s3,24(sp)
    800008d6:	e852                	sd	s4,16(sp)
    800008d8:	e456                	sd	s5,8(sp)
    800008da:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008dc:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008e0:	00011a17          	auipc	s4,0x11
    800008e4:	018a0a13          	addi	s4,s4,24 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008e8:	00008497          	auipc	s1,0x8
    800008ec:	71c48493          	addi	s1,s1,1820 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008f0:	00008997          	auipc	s3,0x8
    800008f4:	71898993          	addi	s3,s3,1816 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008f8:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008fc:	0ff77713          	andi	a4,a4,255
    80000900:	02077713          	andi	a4,a4,32
    80000904:	cb15                	beqz	a4,80000938 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    80000906:	00fa0733          	add	a4,s4,a5
    8000090a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000090e:	2785                	addiw	a5,a5,1
    80000910:	41f7d71b          	sraiw	a4,a5,0x1f
    80000914:	01b7571b          	srliw	a4,a4,0x1b
    80000918:	9fb9                	addw	a5,a5,a4
    8000091a:	8bfd                	andi	a5,a5,31
    8000091c:	9f99                	subw	a5,a5,a4
    8000091e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000920:	8526                	mv	a0,s1
    80000922:	00002097          	auipc	ra,0x2
    80000926:	b14080e7          	jalr	-1260(ra) # 80002436 <wakeup>
    
    WriteReg(THR, c);
    8000092a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000092e:	409c                	lw	a5,0(s1)
    80000930:	0009a703          	lw	a4,0(s3)
    80000934:	fcf712e3          	bne	a4,a5,800008f8 <uartstart+0x42>
  }
}
    80000938:	70e2                	ld	ra,56(sp)
    8000093a:	7442                	ld	s0,48(sp)
    8000093c:	74a2                	ld	s1,40(sp)
    8000093e:	7902                	ld	s2,32(sp)
    80000940:	69e2                	ld	s3,24(sp)
    80000942:	6a42                	ld	s4,16(sp)
    80000944:	6aa2                	ld	s5,8(sp)
    80000946:	6121                	addi	sp,sp,64
    80000948:	8082                	ret
    8000094a:	8082                	ret

000000008000094c <uartputc>:
{
    8000094c:	7179                	addi	sp,sp,-48
    8000094e:	f406                	sd	ra,40(sp)
    80000950:	f022                	sd	s0,32(sp)
    80000952:	ec26                	sd	s1,24(sp)
    80000954:	e84a                	sd	s2,16(sp)
    80000956:	e44e                	sd	s3,8(sp)
    80000958:	e052                	sd	s4,0(sp)
    8000095a:	1800                	addi	s0,sp,48
    8000095c:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    8000095e:	00011517          	auipc	a0,0x11
    80000962:	f9a50513          	addi	a0,a0,-102 # 800118f8 <uart_tx_lock>
    80000966:	00000097          	auipc	ra,0x0
    8000096a:	316080e7          	jalr	790(ra) # 80000c7c <acquire>
  if(panicked){
    8000096e:	00008797          	auipc	a5,0x8
    80000972:	6927a783          	lw	a5,1682(a5) # 80009000 <panicked>
    80000976:	c391                	beqz	a5,8000097a <uartputc+0x2e>
    for(;;)
    80000978:	a001                	j	80000978 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000097a:	00008717          	auipc	a4,0x8
    8000097e:	68e72703          	lw	a4,1678(a4) # 80009008 <uart_tx_w>
    80000982:	0017079b          	addiw	a5,a4,1
    80000986:	41f7d69b          	sraiw	a3,a5,0x1f
    8000098a:	01b6d69b          	srliw	a3,a3,0x1b
    8000098e:	9fb5                	addw	a5,a5,a3
    80000990:	8bfd                	andi	a5,a5,31
    80000992:	9f95                	subw	a5,a5,a3
    80000994:	00008697          	auipc	a3,0x8
    80000998:	6706a683          	lw	a3,1648(a3) # 80009004 <uart_tx_r>
    8000099c:	04f69263          	bne	a3,a5,800009e0 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009a0:	00011a17          	auipc	s4,0x11
    800009a4:	f58a0a13          	addi	s4,s4,-168 # 800118f8 <uart_tx_lock>
    800009a8:	00008497          	auipc	s1,0x8
    800009ac:	65c48493          	addi	s1,s1,1628 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009b0:	00008917          	auipc	s2,0x8
    800009b4:	65890913          	addi	s2,s2,1624 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009b8:	85d2                	mv	a1,s4
    800009ba:	8526                	mv	a0,s1
    800009bc:	00002097          	auipc	ra,0x2
    800009c0:	8f4080e7          	jalr	-1804(ra) # 800022b0 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009c4:	00092703          	lw	a4,0(s2)
    800009c8:	0017079b          	addiw	a5,a4,1
    800009cc:	41f7d69b          	sraiw	a3,a5,0x1f
    800009d0:	01b6d69b          	srliw	a3,a3,0x1b
    800009d4:	9fb5                	addw	a5,a5,a3
    800009d6:	8bfd                	andi	a5,a5,31
    800009d8:	9f95                	subw	a5,a5,a3
    800009da:	4094                	lw	a3,0(s1)
    800009dc:	fcf68ee3          	beq	a3,a5,800009b8 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009e0:	00011497          	auipc	s1,0x11
    800009e4:	f1848493          	addi	s1,s1,-232 # 800118f8 <uart_tx_lock>
    800009e8:	9726                	add	a4,a4,s1
    800009ea:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009ee:	00008717          	auipc	a4,0x8
    800009f2:	60f72d23          	sw	a5,1562(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	ec0080e7          	jalr	-320(ra) # 800008b6 <uartstart>
      release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	330080e7          	jalr	816(ra) # 80000d30 <release>
}
    80000a08:	70a2                	ld	ra,40(sp)
    80000a0a:	7402                	ld	s0,32(sp)
    80000a0c:	64e2                	ld	s1,24(sp)
    80000a0e:	6942                	ld	s2,16(sp)
    80000a10:	69a2                	ld	s3,8(sp)
    80000a12:	6a02                	ld	s4,0(sp)
    80000a14:	6145                	addi	sp,sp,48
    80000a16:	8082                	ret

0000000080000a18 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a18:	1141                	addi	sp,sp,-16
    80000a1a:	e422                	sd	s0,8(sp)
    80000a1c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a1e:	100007b7          	lui	a5,0x10000
    80000a22:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a26:	8b85                	andi	a5,a5,1
    80000a28:	cb91                	beqz	a5,80000a3c <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a2a:	100007b7          	lui	a5,0x10000
    80000a2e:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a32:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a36:	6422                	ld	s0,8(sp)
    80000a38:	0141                	addi	sp,sp,16
    80000a3a:	8082                	ret
    return -1;
    80000a3c:	557d                	li	a0,-1
    80000a3e:	bfe5                	j	80000a36 <uartgetc+0x1e>

0000000080000a40 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a40:	1101                	addi	sp,sp,-32
    80000a42:	ec06                	sd	ra,24(sp)
    80000a44:	e822                	sd	s0,16(sp)
    80000a46:	e426                	sd	s1,8(sp)
    80000a48:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a4a:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	fcc080e7          	jalr	-52(ra) # 80000a18 <uartgetc>
    if(c == -1)
    80000a54:	00950763          	beq	a0,s1,80000a62 <uartintr+0x22>
      break;
    consoleintr(c);
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	870080e7          	jalr	-1936(ra) # 800002c8 <consoleintr>
  while(1){
    80000a60:	b7f5                	j	80000a4c <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a62:	00011497          	auipc	s1,0x11
    80000a66:	e9648493          	addi	s1,s1,-362 # 800118f8 <uart_tx_lock>
    80000a6a:	8526                	mv	a0,s1
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	210080e7          	jalr	528(ra) # 80000c7c <acquire>
  uartstart();
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	e42080e7          	jalr	-446(ra) # 800008b6 <uartstart>
  release(&uart_tx_lock);
    80000a7c:	8526                	mv	a0,s1
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	2b2080e7          	jalr	690(ra) # 80000d30 <release>
}
    80000a86:	60e2                	ld	ra,24(sp)
    80000a88:	6442                	ld	s0,16(sp)
    80000a8a:	64a2                	ld	s1,8(sp)
    80000a8c:	6105                	addi	sp,sp,32
    80000a8e:	8082                	ret

0000000080000a90 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a90:	1101                	addi	sp,sp,-32
    80000a92:	ec06                	sd	ra,24(sp)
    80000a94:	e822                	sd	s0,16(sp)
    80000a96:	e426                	sd	s1,8(sp)
    80000a98:	e04a                	sd	s2,0(sp)
    80000a9a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a9c:	03451793          	slli	a5,a0,0x34
    80000aa0:	ebb9                	bnez	a5,80000af6 <kfree+0x66>
    80000aa2:	84aa                	mv	s1,a0
    80000aa4:	00026797          	auipc	a5,0x26
    80000aa8:	55c78793          	addi	a5,a5,1372 # 80027000 <end>
    80000aac:	04f56563          	bltu	a0,a5,80000af6 <kfree+0x66>
    80000ab0:	47c5                	li	a5,17
    80000ab2:	07ee                	slli	a5,a5,0x1b
    80000ab4:	04f57163          	bgeu	a0,a5,80000af6 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000ab8:	6605                	lui	a2,0x1
    80000aba:	4585                	li	a1,1
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	2bc080e7          	jalr	700(ra) # 80000d78 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ac4:	00011917          	auipc	s2,0x11
    80000ac8:	e6c90913          	addi	s2,s2,-404 # 80011930 <kmem>
    80000acc:	854a                	mv	a0,s2
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	1ae080e7          	jalr	430(ra) # 80000c7c <acquire>
  r->next = kmem.freelist;
    80000ad6:	01893783          	ld	a5,24(s2)
    80000ada:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000adc:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ae0:	854a                	mv	a0,s2
    80000ae2:	00000097          	auipc	ra,0x0
    80000ae6:	24e080e7          	jalr	590(ra) # 80000d30 <release>
}
    80000aea:	60e2                	ld	ra,24(sp)
    80000aec:	6442                	ld	s0,16(sp)
    80000aee:	64a2                	ld	s1,8(sp)
    80000af0:	6902                	ld	s2,0(sp)
    80000af2:	6105                	addi	sp,sp,32
    80000af4:	8082                	ret
    panic("kfree");
    80000af6:	00007517          	auipc	a0,0x7
    80000afa:	58250513          	addi	a0,a0,1410 # 80008078 <digits+0x20>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	a4a080e7          	jalr	-1462(ra) # 80000548 <panic>

0000000080000b06 <freerange>:
{
    80000b06:	7179                	addi	sp,sp,-48
    80000b08:	f406                	sd	ra,40(sp)
    80000b0a:	f022                	sd	s0,32(sp)
    80000b0c:	ec26                	sd	s1,24(sp)
    80000b0e:	e84a                	sd	s2,16(sp)
    80000b10:	e44e                	sd	s3,8(sp)
    80000b12:	e052                	sd	s4,0(sp)
    80000b14:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b16:	6785                	lui	a5,0x1
    80000b18:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b1c:	94aa                	add	s1,s1,a0
    80000b1e:	757d                	lui	a0,0xfffff
    80000b20:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b22:	94be                	add	s1,s1,a5
    80000b24:	0095ee63          	bltu	a1,s1,80000b40 <freerange+0x3a>
    80000b28:	892e                	mv	s2,a1
    kfree(p);
    80000b2a:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b2c:	6985                	lui	s3,0x1
    kfree(p);
    80000b2e:	01448533          	add	a0,s1,s4
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	f5e080e7          	jalr	-162(ra) # 80000a90 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b3a:	94ce                	add	s1,s1,s3
    80000b3c:	fe9979e3          	bgeu	s2,s1,80000b2e <freerange+0x28>
}
    80000b40:	70a2                	ld	ra,40(sp)
    80000b42:	7402                	ld	s0,32(sp)
    80000b44:	64e2                	ld	s1,24(sp)
    80000b46:	6942                	ld	s2,16(sp)
    80000b48:	69a2                	ld	s3,8(sp)
    80000b4a:	6a02                	ld	s4,0(sp)
    80000b4c:	6145                	addi	sp,sp,48
    80000b4e:	8082                	ret

0000000080000b50 <kinit>:
{
    80000b50:	1141                	addi	sp,sp,-16
    80000b52:	e406                	sd	ra,8(sp)
    80000b54:	e022                	sd	s0,0(sp)
    80000b56:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b58:	00007597          	auipc	a1,0x7
    80000b5c:	52858593          	addi	a1,a1,1320 # 80008080 <digits+0x28>
    80000b60:	00011517          	auipc	a0,0x11
    80000b64:	dd050513          	addi	a0,a0,-560 # 80011930 <kmem>
    80000b68:	00000097          	auipc	ra,0x0
    80000b6c:	084080e7          	jalr	132(ra) # 80000bec <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b70:	45c5                	li	a1,17
    80000b72:	05ee                	slli	a1,a1,0x1b
    80000b74:	00026517          	auipc	a0,0x26
    80000b78:	48c50513          	addi	a0,a0,1164 # 80027000 <end>
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	f8a080e7          	jalr	-118(ra) # 80000b06 <freerange>
}
    80000b84:	60a2                	ld	ra,8(sp)
    80000b86:	6402                	ld	s0,0(sp)
    80000b88:	0141                	addi	sp,sp,16
    80000b8a:	8082                	ret

0000000080000b8c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b96:	00011497          	auipc	s1,0x11
    80000b9a:	d9a48493          	addi	s1,s1,-614 # 80011930 <kmem>
    80000b9e:	8526                	mv	a0,s1
    80000ba0:	00000097          	auipc	ra,0x0
    80000ba4:	0dc080e7          	jalr	220(ra) # 80000c7c <acquire>
  r = kmem.freelist;
    80000ba8:	6c84                	ld	s1,24(s1)
  if(r)
    80000baa:	c885                	beqz	s1,80000bda <kalloc+0x4e>
    kmem.freelist = r->next;
    80000bac:	609c                	ld	a5,0(s1)
    80000bae:	00011517          	auipc	a0,0x11
    80000bb2:	d8250513          	addi	a0,a0,-638 # 80011930 <kmem>
    80000bb6:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bb8:	00000097          	auipc	ra,0x0
    80000bbc:	178080e7          	jalr	376(ra) # 80000d30 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bc0:	6605                	lui	a2,0x1
    80000bc2:	4595                	li	a1,5
    80000bc4:	8526                	mv	a0,s1
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	1b2080e7          	jalr	434(ra) # 80000d78 <memset>
  return (void*)r;
}
    80000bce:	8526                	mv	a0,s1
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
  release(&kmem.lock);
    80000bda:	00011517          	auipc	a0,0x11
    80000bde:	d5650513          	addi	a0,a0,-682 # 80011930 <kmem>
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	14e080e7          	jalr	334(ra) # 80000d30 <release>
  if(r)
    80000bea:	b7d5                	j	80000bce <kalloc+0x42>

0000000080000bec <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bec:	1141                	addi	sp,sp,-16
    80000bee:	e422                	sd	s0,8(sp)
    80000bf0:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bf2:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bf4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bf8:	00053823          	sd	zero,16(a0)
}
    80000bfc:	6422                	ld	s0,8(sp)
    80000bfe:	0141                	addi	sp,sp,16
    80000c00:	8082                	ret

0000000080000c02 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c02:	411c                	lw	a5,0(a0)
    80000c04:	e399                	bnez	a5,80000c0a <holding+0x8>
    80000c06:	4501                	li	a0,0
  return r;
}
    80000c08:	8082                	ret
{
    80000c0a:	1101                	addi	sp,sp,-32
    80000c0c:	ec06                	sd	ra,24(sp)
    80000c0e:	e822                	sd	s0,16(sp)
    80000c10:	e426                	sd	s1,8(sp)
    80000c12:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c14:	6904                	ld	s1,16(a0)
    80000c16:	00001097          	auipc	ra,0x1
    80000c1a:	e18080e7          	jalr	-488(ra) # 80001a2e <mycpu>
    80000c1e:	40a48533          	sub	a0,s1,a0
    80000c22:	00153513          	seqz	a0,a0
}
    80000c26:	60e2                	ld	ra,24(sp)
    80000c28:	6442                	ld	s0,16(sp)
    80000c2a:	64a2                	ld	s1,8(sp)
    80000c2c:	6105                	addi	sp,sp,32
    80000c2e:	8082                	ret

0000000080000c30 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c30:	1101                	addi	sp,sp,-32
    80000c32:	ec06                	sd	ra,24(sp)
    80000c34:	e822                	sd	s0,16(sp)
    80000c36:	e426                	sd	s1,8(sp)
    80000c38:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100024f3          	csrr	s1,sstatus
    80000c3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c44:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c48:	00001097          	auipc	ra,0x1
    80000c4c:	de6080e7          	jalr	-538(ra) # 80001a2e <mycpu>
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	cf89                	beqz	a5,80000c6c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c54:	00001097          	auipc	ra,0x1
    80000c58:	dda080e7          	jalr	-550(ra) # 80001a2e <mycpu>
    80000c5c:	5d3c                	lw	a5,120(a0)
    80000c5e:	2785                	addiw	a5,a5,1
    80000c60:	dd3c                	sw	a5,120(a0)
}
    80000c62:	60e2                	ld	ra,24(sp)
    80000c64:	6442                	ld	s0,16(sp)
    80000c66:	64a2                	ld	s1,8(sp)
    80000c68:	6105                	addi	sp,sp,32
    80000c6a:	8082                	ret
    mycpu()->intena = old;
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	dc2080e7          	jalr	-574(ra) # 80001a2e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c74:	8085                	srli	s1,s1,0x1
    80000c76:	8885                	andi	s1,s1,1
    80000c78:	dd64                	sw	s1,124(a0)
    80000c7a:	bfe9                	j	80000c54 <push_off+0x24>

0000000080000c7c <acquire>:
{
    80000c7c:	1101                	addi	sp,sp,-32
    80000c7e:	ec06                	sd	ra,24(sp)
    80000c80:	e822                	sd	s0,16(sp)
    80000c82:	e426                	sd	s1,8(sp)
    80000c84:	1000                	addi	s0,sp,32
    80000c86:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c88:	00000097          	auipc	ra,0x0
    80000c8c:	fa8080e7          	jalr	-88(ra) # 80000c30 <push_off>
  if(holding(lk))
    80000c90:	8526                	mv	a0,s1
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	f70080e7          	jalr	-144(ra) # 80000c02 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c9a:	4705                	li	a4,1
  if(holding(lk))
    80000c9c:	e115                	bnez	a0,80000cc0 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c9e:	87ba                	mv	a5,a4
    80000ca0:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000ca4:	2781                	sext.w	a5,a5
    80000ca6:	ffe5                	bnez	a5,80000c9e <acquire+0x22>
  __sync_synchronize();
    80000ca8:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cac:	00001097          	auipc	ra,0x1
    80000cb0:	d82080e7          	jalr	-638(ra) # 80001a2e <mycpu>
    80000cb4:	e888                	sd	a0,16(s1)
}
    80000cb6:	60e2                	ld	ra,24(sp)
    80000cb8:	6442                	ld	s0,16(sp)
    80000cba:	64a2                	ld	s1,8(sp)
    80000cbc:	6105                	addi	sp,sp,32
    80000cbe:	8082                	ret
    panic("acquire");
    80000cc0:	00007517          	auipc	a0,0x7
    80000cc4:	3c850513          	addi	a0,a0,968 # 80008088 <digits+0x30>
    80000cc8:	00000097          	auipc	ra,0x0
    80000ccc:	880080e7          	jalr	-1920(ra) # 80000548 <panic>

0000000080000cd0 <pop_off>:

void
pop_off(void)
{
    80000cd0:	1141                	addi	sp,sp,-16
    80000cd2:	e406                	sd	ra,8(sp)
    80000cd4:	e022                	sd	s0,0(sp)
    80000cd6:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cd8:	00001097          	auipc	ra,0x1
    80000cdc:	d56080e7          	jalr	-682(ra) # 80001a2e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ce4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ce6:	e78d                	bnez	a5,80000d10 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ce8:	5d3c                	lw	a5,120(a0)
    80000cea:	02f05b63          	blez	a5,80000d20 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cee:	37fd                	addiw	a5,a5,-1
    80000cf0:	0007871b          	sext.w	a4,a5
    80000cf4:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cf6:	eb09                	bnez	a4,80000d08 <pop_off+0x38>
    80000cf8:	5d7c                	lw	a5,124(a0)
    80000cfa:	c799                	beqz	a5,80000d08 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cfc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d00:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d04:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d08:	60a2                	ld	ra,8(sp)
    80000d0a:	6402                	ld	s0,0(sp)
    80000d0c:	0141                	addi	sp,sp,16
    80000d0e:	8082                	ret
    panic("pop_off - interruptible");
    80000d10:	00007517          	auipc	a0,0x7
    80000d14:	38050513          	addi	a0,a0,896 # 80008090 <digits+0x38>
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	830080e7          	jalr	-2000(ra) # 80000548 <panic>
    panic("pop_off");
    80000d20:	00007517          	auipc	a0,0x7
    80000d24:	38850513          	addi	a0,a0,904 # 800080a8 <digits+0x50>
    80000d28:	00000097          	auipc	ra,0x0
    80000d2c:	820080e7          	jalr	-2016(ra) # 80000548 <panic>

0000000080000d30 <release>:
{
    80000d30:	1101                	addi	sp,sp,-32
    80000d32:	ec06                	sd	ra,24(sp)
    80000d34:	e822                	sd	s0,16(sp)
    80000d36:	e426                	sd	s1,8(sp)
    80000d38:	1000                	addi	s0,sp,32
    80000d3a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	ec6080e7          	jalr	-314(ra) # 80000c02 <holding>
    80000d44:	c115                	beqz	a0,80000d68 <release+0x38>
  lk->cpu = 0;
    80000d46:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d4a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d4e:	0f50000f          	fence	iorw,ow
    80000d52:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d56:	00000097          	auipc	ra,0x0
    80000d5a:	f7a080e7          	jalr	-134(ra) # 80000cd0 <pop_off>
}
    80000d5e:	60e2                	ld	ra,24(sp)
    80000d60:	6442                	ld	s0,16(sp)
    80000d62:	64a2                	ld	s1,8(sp)
    80000d64:	6105                	addi	sp,sp,32
    80000d66:	8082                	ret
    panic("release");
    80000d68:	00007517          	auipc	a0,0x7
    80000d6c:	34850513          	addi	a0,a0,840 # 800080b0 <digits+0x58>
    80000d70:	fffff097          	auipc	ra,0xfffff
    80000d74:	7d8080e7          	jalr	2008(ra) # 80000548 <panic>

0000000080000d78 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d78:	1141                	addi	sp,sp,-16
    80000d7a:	e422                	sd	s0,8(sp)
    80000d7c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d7e:	ce09                	beqz	a2,80000d98 <memset+0x20>
    80000d80:	87aa                	mv	a5,a0
    80000d82:	fff6071b          	addiw	a4,a2,-1
    80000d86:	1702                	slli	a4,a4,0x20
    80000d88:	9301                	srli	a4,a4,0x20
    80000d8a:	0705                	addi	a4,a4,1
    80000d8c:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d8e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d92:	0785                	addi	a5,a5,1
    80000d94:	fee79de3          	bne	a5,a4,80000d8e <memset+0x16>
  }
  return dst;
}
    80000d98:	6422                	ld	s0,8(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000da4:	ca05                	beqz	a2,80000dd4 <memcmp+0x36>
    80000da6:	fff6069b          	addiw	a3,a2,-1
    80000daa:	1682                	slli	a3,a3,0x20
    80000dac:	9281                	srli	a3,a3,0x20
    80000dae:	0685                	addi	a3,a3,1
    80000db0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000db2:	00054783          	lbu	a5,0(a0)
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	00e79863          	bne	a5,a4,80000dca <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dbe:	0505                	addi	a0,a0,1
    80000dc0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dc2:	fed518e3          	bne	a0,a3,80000db2 <memcmp+0x14>
  }

  return 0;
    80000dc6:	4501                	li	a0,0
    80000dc8:	a019                	j	80000dce <memcmp+0x30>
      return *s1 - *s2;
    80000dca:	40e7853b          	subw	a0,a5,a4
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
  return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <memcmp+0x30>

0000000080000dd8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dde:	00a5f963          	bgeu	a1,a0,80000df0 <memmove+0x18>
    80000de2:	02061713          	slli	a4,a2,0x20
    80000de6:	9301                	srli	a4,a4,0x20
    80000de8:	00e587b3          	add	a5,a1,a4
    80000dec:	02f56563          	bltu	a0,a5,80000e16 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000df0:	fff6069b          	addiw	a3,a2,-1
    80000df4:	ce11                	beqz	a2,80000e10 <memmove+0x38>
    80000df6:	1682                	slli	a3,a3,0x20
    80000df8:	9281                	srli	a3,a3,0x20
    80000dfa:	0685                	addi	a3,a3,1
    80000dfc:	96ae                	add	a3,a3,a1
    80000dfe:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e00:	0585                	addi	a1,a1,1
    80000e02:	0785                	addi	a5,a5,1
    80000e04:	fff5c703          	lbu	a4,-1(a1)
    80000e08:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e0c:	fed59ae3          	bne	a1,a3,80000e00 <memmove+0x28>

  return dst;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret
    d += n;
    80000e16:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e18:	fff6069b          	addiw	a3,a2,-1
    80000e1c:	da75                	beqz	a2,80000e10 <memmove+0x38>
    80000e1e:	02069613          	slli	a2,a3,0x20
    80000e22:	9201                	srli	a2,a2,0x20
    80000e24:	fff64613          	not	a2,a2
    80000e28:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e2a:	17fd                	addi	a5,a5,-1
    80000e2c:	177d                	addi	a4,a4,-1
    80000e2e:	0007c683          	lbu	a3,0(a5)
    80000e32:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e36:	fec79ae3          	bne	a5,a2,80000e2a <memmove+0x52>
    80000e3a:	bfd9                	j	80000e10 <memmove+0x38>

0000000080000e3c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e44:	00000097          	auipc	ra,0x0
    80000e48:	f94080e7          	jalr	-108(ra) # 80000dd8 <memmove>
}
    80000e4c:	60a2                	ld	ra,8(sp)
    80000e4e:	6402                	ld	s0,0(sp)
    80000e50:	0141                	addi	sp,sp,16
    80000e52:	8082                	ret

0000000080000e54 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e54:	1141                	addi	sp,sp,-16
    80000e56:	e422                	sd	s0,8(sp)
    80000e58:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e5a:	ce11                	beqz	a2,80000e76 <strncmp+0x22>
    80000e5c:	00054783          	lbu	a5,0(a0)
    80000e60:	cf89                	beqz	a5,80000e7a <strncmp+0x26>
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	00f71a63          	bne	a4,a5,80000e7a <strncmp+0x26>
    n--, p++, q++;
    80000e6a:	367d                	addiw	a2,a2,-1
    80000e6c:	0505                	addi	a0,a0,1
    80000e6e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e70:	f675                	bnez	a2,80000e5c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e72:	4501                	li	a0,0
    80000e74:	a809                	j	80000e86 <strncmp+0x32>
    80000e76:	4501                	li	a0,0
    80000e78:	a039                	j	80000e86 <strncmp+0x32>
  if(n == 0)
    80000e7a:	ca09                	beqz	a2,80000e8c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e7c:	00054503          	lbu	a0,0(a0)
    80000e80:	0005c783          	lbu	a5,0(a1)
    80000e84:	9d1d                	subw	a0,a0,a5
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret
    return 0;
    80000e8c:	4501                	li	a0,0
    80000e8e:	bfe5                	j	80000e86 <strncmp+0x32>

0000000080000e90 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e90:	1141                	addi	sp,sp,-16
    80000e92:	e422                	sd	s0,8(sp)
    80000e94:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e96:	872a                	mv	a4,a0
    80000e98:	8832                	mv	a6,a2
    80000e9a:	367d                	addiw	a2,a2,-1
    80000e9c:	01005963          	blez	a6,80000eae <strncpy+0x1e>
    80000ea0:	0705                	addi	a4,a4,1
    80000ea2:	0005c783          	lbu	a5,0(a1)
    80000ea6:	fef70fa3          	sb	a5,-1(a4)
    80000eaa:	0585                	addi	a1,a1,1
    80000eac:	f7f5                	bnez	a5,80000e98 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000eae:	00c05d63          	blez	a2,80000ec8 <strncpy+0x38>
    80000eb2:	86ba                	mv	a3,a4
    *s++ = 0;
    80000eb4:	0685                	addi	a3,a3,1
    80000eb6:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eba:	fff6c793          	not	a5,a3
    80000ebe:	9fb9                	addw	a5,a5,a4
    80000ec0:	010787bb          	addw	a5,a5,a6
    80000ec4:	fef048e3          	bgtz	a5,80000eb4 <strncpy+0x24>
  return os;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret

0000000080000ece <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ece:	1141                	addi	sp,sp,-16
    80000ed0:	e422                	sd	s0,8(sp)
    80000ed2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ed4:	02c05363          	blez	a2,80000efa <safestrcpy+0x2c>
    80000ed8:	fff6069b          	addiw	a3,a2,-1
    80000edc:	1682                	slli	a3,a3,0x20
    80000ede:	9281                	srli	a3,a3,0x20
    80000ee0:	96ae                	add	a3,a3,a1
    80000ee2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ee4:	00d58963          	beq	a1,a3,80000ef6 <safestrcpy+0x28>
    80000ee8:	0585                	addi	a1,a1,1
    80000eea:	0785                	addi	a5,a5,1
    80000eec:	fff5c703          	lbu	a4,-1(a1)
    80000ef0:	fee78fa3          	sb	a4,-1(a5)
    80000ef4:	fb65                	bnez	a4,80000ee4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ef6:	00078023          	sb	zero,0(a5)
  return os;
}
    80000efa:	6422                	ld	s0,8(sp)
    80000efc:	0141                	addi	sp,sp,16
    80000efe:	8082                	ret

0000000080000f00 <strlen>:

int
strlen(const char *s)
{
    80000f00:	1141                	addi	sp,sp,-16
    80000f02:	e422                	sd	s0,8(sp)
    80000f04:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f06:	00054783          	lbu	a5,0(a0)
    80000f0a:	cf91                	beqz	a5,80000f26 <strlen+0x26>
    80000f0c:	0505                	addi	a0,a0,1
    80000f0e:	87aa                	mv	a5,a0
    80000f10:	4685                	li	a3,1
    80000f12:	9e89                	subw	a3,a3,a0
    80000f14:	00f6853b          	addw	a0,a3,a5
    80000f18:	0785                	addi	a5,a5,1
    80000f1a:	fff7c703          	lbu	a4,-1(a5)
    80000f1e:	fb7d                	bnez	a4,80000f14 <strlen+0x14>
    ;
  return n;
}
    80000f20:	6422                	ld	s0,8(sp)
    80000f22:	0141                	addi	sp,sp,16
    80000f24:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f26:	4501                	li	a0,0
    80000f28:	bfe5                	j	80000f20 <strlen+0x20>

0000000080000f2a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f2a:	1141                	addi	sp,sp,-16
    80000f2c:	e406                	sd	ra,8(sp)
    80000f2e:	e022                	sd	s0,0(sp)
    80000f30:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	aec080e7          	jalr	-1300(ra) # 80001a1e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f3a:	00008717          	auipc	a4,0x8
    80000f3e:	0d270713          	addi	a4,a4,210 # 8000900c <started>
  if(cpuid() == 0){
    80000f42:	c139                	beqz	a0,80000f88 <main+0x5e>
    while(started == 0)
    80000f44:	431c                	lw	a5,0(a4)
    80000f46:	2781                	sext.w	a5,a5
    80000f48:	dff5                	beqz	a5,80000f44 <main+0x1a>
      ;
    __sync_synchronize();
    80000f4a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	ad0080e7          	jalr	-1328(ra) # 80001a1e <cpuid>
    80000f56:	85aa                	mv	a1,a0
    80000f58:	00007517          	auipc	a0,0x7
    80000f5c:	17850513          	addi	a0,a0,376 # 800080d0 <digits+0x78>
    80000f60:	fffff097          	auipc	ra,0xfffff
    80000f64:	632080e7          	jalr	1586(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f68:	00000097          	auipc	ra,0x0
    80000f6c:	0d8080e7          	jalr	216(ra) # 80001040 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	78e080e7          	jalr	1934(ra) # 800026fe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f78:	00005097          	auipc	ra,0x5
    80000f7c:	e08080e7          	jalr	-504(ra) # 80005d80 <plicinithart>
  }

  scheduler();        
    80000f80:	00001097          	auipc	ra,0x1
    80000f84:	054080e7          	jalr	84(ra) # 80001fd4 <scheduler>
    consoleinit();
    80000f88:	fffff097          	auipc	ra,0xfffff
    80000f8c:	4d2080e7          	jalr	1234(ra) # 8000045a <consoleinit>
    printfinit();
    80000f90:	00000097          	auipc	ra,0x0
    80000f94:	854080e7          	jalr	-1964(ra) # 800007e4 <printfinit>
    printf("\n");
    80000f98:	00007517          	auipc	a0,0x7
    80000f9c:	14850513          	addi	a0,a0,328 # 800080e0 <digits+0x88>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	5f2080e7          	jalr	1522(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	11050513          	addi	a0,a0,272 # 800080b8 <digits+0x60>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5e2080e7          	jalr	1506(ra) # 80000592 <printf>
    printf("\n");
    80000fb8:	00007517          	auipc	a0,0x7
    80000fbc:	12850513          	addi	a0,a0,296 # 800080e0 <digits+0x88>
    80000fc0:	fffff097          	auipc	ra,0xfffff
    80000fc4:	5d2080e7          	jalr	1490(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	b88080e7          	jalr	-1144(ra) # 80000b50 <kinit>
    kvminit();       // create kernel page table
    80000fd0:	00000097          	auipc	ra,0x0
    80000fd4:	2a0080e7          	jalr	672(ra) # 80001270 <kvminit>
    kvminithart();   // turn on paging
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	068080e7          	jalr	104(ra) # 80001040 <kvminithart>
    procinit();      // process table
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	96e080e7          	jalr	-1682(ra) # 8000194e <procinit>
    trapinit();      // trap vectors
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	6ee080e7          	jalr	1774(ra) # 800026d6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	70e080e7          	jalr	1806(ra) # 800026fe <trapinithart>
    plicinit();      // set up interrupt controller
    80000ff8:	00005097          	auipc	ra,0x5
    80000ffc:	d72080e7          	jalr	-654(ra) # 80005d6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	d80080e7          	jalr	-640(ra) # 80005d80 <plicinithart>
    binit();         // buffer cache
    80001008:	00002097          	auipc	ra,0x2
    8000100c:	f20080e7          	jalr	-224(ra) # 80002f28 <binit>
    iinit();         // inode cache
    80001010:	00002097          	auipc	ra,0x2
    80001014:	5b0080e7          	jalr	1456(ra) # 800035c0 <iinit>
    fileinit();      // file table
    80001018:	00003097          	auipc	ra,0x3
    8000101c:	54a080e7          	jalr	1354(ra) # 80004562 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001020:	00005097          	auipc	ra,0x5
    80001024:	e68080e7          	jalr	-408(ra) # 80005e88 <virtio_disk_init>
    userinit();      // first user process
    80001028:	00001097          	auipc	ra,0x1
    8000102c:	d46080e7          	jalr	-698(ra) # 80001d6e <userinit>
    __sync_synchronize();
    80001030:	0ff0000f          	fence
    started = 1;
    80001034:	4785                	li	a5,1
    80001036:	00008717          	auipc	a4,0x8
    8000103a:	fcf72b23          	sw	a5,-42(a4) # 8000900c <started>
    8000103e:	b789                	j	80000f80 <main+0x56>

0000000080001040 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001040:	1141                	addi	sp,sp,-16
    80001042:	e422                	sd	s0,8(sp)
    80001044:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001046:	00008797          	auipc	a5,0x8
    8000104a:	fca7b783          	ld	a5,-54(a5) # 80009010 <kernel_pagetable>
    8000104e:	83b1                	srli	a5,a5,0xc
    80001050:	577d                	li	a4,-1
    80001052:	177e                	slli	a4,a4,0x3f
    80001054:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001056:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000105a:	12000073          	sfence.vma
  sfence_vma();
}
    8000105e:	6422                	ld	s0,8(sp)
    80001060:	0141                	addi	sp,sp,16
    80001062:	8082                	ret

0000000080001064 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001064:	7139                	addi	sp,sp,-64
    80001066:	fc06                	sd	ra,56(sp)
    80001068:	f822                	sd	s0,48(sp)
    8000106a:	f426                	sd	s1,40(sp)
    8000106c:	f04a                	sd	s2,32(sp)
    8000106e:	ec4e                	sd	s3,24(sp)
    80001070:	e852                	sd	s4,16(sp)
    80001072:	e456                	sd	s5,8(sp)
    80001074:	e05a                	sd	s6,0(sp)
    80001076:	0080                	addi	s0,sp,64
    80001078:	84aa                	mv	s1,a0
    8000107a:	89ae                	mv	s3,a1
    8000107c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000107e:	57fd                	li	a5,-1
    80001080:	83e9                	srli	a5,a5,0x1a
    80001082:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001084:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001086:	04b7f263          	bgeu	a5,a1,800010ca <walk+0x66>
    panic("walk");
    8000108a:	00007517          	auipc	a0,0x7
    8000108e:	05e50513          	addi	a0,a0,94 # 800080e8 <digits+0x90>
    80001092:	fffff097          	auipc	ra,0xfffff
    80001096:	4b6080e7          	jalr	1206(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000109a:	060a8663          	beqz	s5,80001106 <walk+0xa2>
    8000109e:	00000097          	auipc	ra,0x0
    800010a2:	aee080e7          	jalr	-1298(ra) # 80000b8c <kalloc>
    800010a6:	84aa                	mv	s1,a0
    800010a8:	c529                	beqz	a0,800010f2 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010aa:	6605                	lui	a2,0x1
    800010ac:	4581                	li	a1,0
    800010ae:	00000097          	auipc	ra,0x0
    800010b2:	cca080e7          	jalr	-822(ra) # 80000d78 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010b6:	00c4d793          	srli	a5,s1,0xc
    800010ba:	07aa                	slli	a5,a5,0xa
    800010bc:	0017e793          	ori	a5,a5,1
    800010c0:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010c4:	3a5d                	addiw	s4,s4,-9
    800010c6:	036a0063          	beq	s4,s6,800010e6 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010ca:	0149d933          	srl	s2,s3,s4
    800010ce:	1ff97913          	andi	s2,s2,511
    800010d2:	090e                	slli	s2,s2,0x3
    800010d4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010d6:	00093483          	ld	s1,0(s2)
    800010da:	0014f793          	andi	a5,s1,1
    800010de:	dfd5                	beqz	a5,8000109a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e0:	80a9                	srli	s1,s1,0xa
    800010e2:	04b2                	slli	s1,s1,0xc
    800010e4:	b7c5                	j	800010c4 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010e6:	00c9d513          	srli	a0,s3,0xc
    800010ea:	1ff57513          	andi	a0,a0,511
    800010ee:	050e                	slli	a0,a0,0x3
    800010f0:	9526                	add	a0,a0,s1
}
    800010f2:	70e2                	ld	ra,56(sp)
    800010f4:	7442                	ld	s0,48(sp)
    800010f6:	74a2                	ld	s1,40(sp)
    800010f8:	7902                	ld	s2,32(sp)
    800010fa:	69e2                	ld	s3,24(sp)
    800010fc:	6a42                	ld	s4,16(sp)
    800010fe:	6aa2                	ld	s5,8(sp)
    80001100:	6b02                	ld	s6,0(sp)
    80001102:	6121                	addi	sp,sp,64
    80001104:	8082                	ret
        return 0;
    80001106:	4501                	li	a0,0
    80001108:	b7ed                	j	800010f2 <walk+0x8e>

000000008000110a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000110a:	57fd                	li	a5,-1
    8000110c:	83e9                	srli	a5,a5,0x1a
    8000110e:	00b7f463          	bgeu	a5,a1,80001116 <walkaddr+0xc>
    return 0;
    80001112:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001114:	8082                	ret
{
    80001116:	1141                	addi	sp,sp,-16
    80001118:	e406                	sd	ra,8(sp)
    8000111a:	e022                	sd	s0,0(sp)
    8000111c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000111e:	4601                	li	a2,0
    80001120:	00000097          	auipc	ra,0x0
    80001124:	f44080e7          	jalr	-188(ra) # 80001064 <walk>
  if(pte == 0)
    80001128:	c105                	beqz	a0,80001148 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000112a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000112c:	0117f693          	andi	a3,a5,17
    80001130:	4745                	li	a4,17
    return 0;
    80001132:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001134:	00e68663          	beq	a3,a4,80001140 <walkaddr+0x36>
}
    80001138:	60a2                	ld	ra,8(sp)
    8000113a:	6402                	ld	s0,0(sp)
    8000113c:	0141                	addi	sp,sp,16
    8000113e:	8082                	ret
  pa = PTE2PA(*pte);
    80001140:	00a7d513          	srli	a0,a5,0xa
    80001144:	0532                	slli	a0,a0,0xc
  return pa;
    80001146:	bfcd                	j	80001138 <walkaddr+0x2e>
    return 0;
    80001148:	4501                	li	a0,0
    8000114a:	b7fd                	j	80001138 <walkaddr+0x2e>

000000008000114c <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	1000                	addi	s0,sp,32
    80001156:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001158:	1552                	slli	a0,a0,0x34
    8000115a:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000115e:	4601                	li	a2,0
    80001160:	00008517          	auipc	a0,0x8
    80001164:	eb053503          	ld	a0,-336(a0) # 80009010 <kernel_pagetable>
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	efc080e7          	jalr	-260(ra) # 80001064 <walk>
  if(pte == 0)
    80001170:	cd09                	beqz	a0,8000118a <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001172:	6108                	ld	a0,0(a0)
    80001174:	00157793          	andi	a5,a0,1
    80001178:	c38d                	beqz	a5,8000119a <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000117a:	8129                	srli	a0,a0,0xa
    8000117c:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000117e:	9526                	add	a0,a0,s1
    80001180:	60e2                	ld	ra,24(sp)
    80001182:	6442                	ld	s0,16(sp)
    80001184:	64a2                	ld	s1,8(sp)
    80001186:	6105                	addi	sp,sp,32
    80001188:	8082                	ret
    panic("kvmpa");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f6650513          	addi	a0,a0,-154 # 800080f0 <digits+0x98>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3b6080e7          	jalr	950(ra) # 80000548 <panic>
    panic("kvmpa");
    8000119a:	00007517          	auipc	a0,0x7
    8000119e:	f5650513          	addi	a0,a0,-170 # 800080f0 <digits+0x98>
    800011a2:	fffff097          	auipc	ra,0xfffff
    800011a6:	3a6080e7          	jalr	934(ra) # 80000548 <panic>

00000000800011aa <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011aa:	715d                	addi	sp,sp,-80
    800011ac:	e486                	sd	ra,72(sp)
    800011ae:	e0a2                	sd	s0,64(sp)
    800011b0:	fc26                	sd	s1,56(sp)
    800011b2:	f84a                	sd	s2,48(sp)
    800011b4:	f44e                	sd	s3,40(sp)
    800011b6:	f052                	sd	s4,32(sp)
    800011b8:	ec56                	sd	s5,24(sp)
    800011ba:	e85a                	sd	s6,16(sp)
    800011bc:	e45e                	sd	s7,8(sp)
    800011be:	0880                	addi	s0,sp,80
    800011c0:	8aaa                	mv	s5,a0
    800011c2:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011c4:	777d                	lui	a4,0xfffff
    800011c6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011ca:	167d                	addi	a2,a2,-1
    800011cc:	00b609b3          	add	s3,a2,a1
    800011d0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011d4:	893e                	mv	s2,a5
    800011d6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011da:	6b85                	lui	s7,0x1
    800011dc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e0:	4605                	li	a2,1
    800011e2:	85ca                	mv	a1,s2
    800011e4:	8556                	mv	a0,s5
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	e7e080e7          	jalr	-386(ra) # 80001064 <walk>
    800011ee:	c51d                	beqz	a0,8000121c <mappages+0x72>
    if(*pte & PTE_V)
    800011f0:	611c                	ld	a5,0(a0)
    800011f2:	8b85                	andi	a5,a5,1
    800011f4:	ef81                	bnez	a5,8000120c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011f6:	80b1                	srli	s1,s1,0xc
    800011f8:	04aa                	slli	s1,s1,0xa
    800011fa:	0164e4b3          	or	s1,s1,s6
    800011fe:	0014e493          	ori	s1,s1,1
    80001202:	e104                	sd	s1,0(a0)
    if(a == last)
    80001204:	03390863          	beq	s2,s3,80001234 <mappages+0x8a>
    a += PGSIZE;
    80001208:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000120a:	bfc9                	j	800011dc <mappages+0x32>
      panic("remap");
    8000120c:	00007517          	auipc	a0,0x7
    80001210:	eec50513          	addi	a0,a0,-276 # 800080f8 <digits+0xa0>
    80001214:	fffff097          	auipc	ra,0xfffff
    80001218:	334080e7          	jalr	820(ra) # 80000548 <panic>
      return -1;
    8000121c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000121e:	60a6                	ld	ra,72(sp)
    80001220:	6406                	ld	s0,64(sp)
    80001222:	74e2                	ld	s1,56(sp)
    80001224:	7942                	ld	s2,48(sp)
    80001226:	79a2                	ld	s3,40(sp)
    80001228:	7a02                	ld	s4,32(sp)
    8000122a:	6ae2                	ld	s5,24(sp)
    8000122c:	6b42                	ld	s6,16(sp)
    8000122e:	6ba2                	ld	s7,8(sp)
    80001230:	6161                	addi	sp,sp,80
    80001232:	8082                	ret
  return 0;
    80001234:	4501                	li	a0,0
    80001236:	b7e5                	j	8000121e <mappages+0x74>

0000000080001238 <kvmmap>:
{
    80001238:	1141                	addi	sp,sp,-16
    8000123a:	e406                	sd	ra,8(sp)
    8000123c:	e022                	sd	s0,0(sp)
    8000123e:	0800                	addi	s0,sp,16
    80001240:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001242:	86ae                	mv	a3,a1
    80001244:	85aa                	mv	a1,a0
    80001246:	00008517          	auipc	a0,0x8
    8000124a:	dca53503          	ld	a0,-566(a0) # 80009010 <kernel_pagetable>
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	f5c080e7          	jalr	-164(ra) # 800011aa <mappages>
    80001256:	e509                	bnez	a0,80001260 <kvmmap+0x28>
}
    80001258:	60a2                	ld	ra,8(sp)
    8000125a:	6402                	ld	s0,0(sp)
    8000125c:	0141                	addi	sp,sp,16
    8000125e:	8082                	ret
    panic("kvmmap");
    80001260:	00007517          	auipc	a0,0x7
    80001264:	ea050513          	addi	a0,a0,-352 # 80008100 <digits+0xa8>
    80001268:	fffff097          	auipc	ra,0xfffff
    8000126c:	2e0080e7          	jalr	736(ra) # 80000548 <panic>

0000000080001270 <kvminit>:
{
    80001270:	1101                	addi	sp,sp,-32
    80001272:	ec06                	sd	ra,24(sp)
    80001274:	e822                	sd	s0,16(sp)
    80001276:	e426                	sd	s1,8(sp)
    80001278:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000127a:	00000097          	auipc	ra,0x0
    8000127e:	912080e7          	jalr	-1774(ra) # 80000b8c <kalloc>
    80001282:	00008797          	auipc	a5,0x8
    80001286:	d8a7b723          	sd	a0,-626(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000128a:	6605                	lui	a2,0x1
    8000128c:	4581                	li	a1,0
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	aea080e7          	jalr	-1302(ra) # 80000d78 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001296:	4699                	li	a3,6
    80001298:	6605                	lui	a2,0x1
    8000129a:	100005b7          	lui	a1,0x10000
    8000129e:	10000537          	lui	a0,0x10000
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f96080e7          	jalr	-106(ra) # 80001238 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012aa:	4699                	li	a3,6
    800012ac:	6605                	lui	a2,0x1
    800012ae:	100015b7          	lui	a1,0x10001
    800012b2:	10001537          	lui	a0,0x10001
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f82080e7          	jalr	-126(ra) # 80001238 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012be:	4699                	li	a3,6
    800012c0:	6641                	lui	a2,0x10
    800012c2:	020005b7          	lui	a1,0x2000
    800012c6:	02000537          	lui	a0,0x2000
    800012ca:	00000097          	auipc	ra,0x0
    800012ce:	f6e080e7          	jalr	-146(ra) # 80001238 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012d2:	4699                	li	a3,6
    800012d4:	00400637          	lui	a2,0x400
    800012d8:	0c0005b7          	lui	a1,0xc000
    800012dc:	0c000537          	lui	a0,0xc000
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	f58080e7          	jalr	-168(ra) # 80001238 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e8:	00007497          	auipc	s1,0x7
    800012ec:	d1848493          	addi	s1,s1,-744 # 80008000 <etext>
    800012f0:	46a9                	li	a3,10
    800012f2:	80007617          	auipc	a2,0x80007
    800012f6:	d0e60613          	addi	a2,a2,-754 # 8000 <_entry-0x7fff8000>
    800012fa:	4585                	li	a1,1
    800012fc:	05fe                	slli	a1,a1,0x1f
    800012fe:	852e                	mv	a0,a1
    80001300:	00000097          	auipc	ra,0x0
    80001304:	f38080e7          	jalr	-200(ra) # 80001238 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001308:	4699                	li	a3,6
    8000130a:	4645                	li	a2,17
    8000130c:	066e                	slli	a2,a2,0x1b
    8000130e:	8e05                	sub	a2,a2,s1
    80001310:	85a6                	mv	a1,s1
    80001312:	8526                	mv	a0,s1
    80001314:	00000097          	auipc	ra,0x0
    80001318:	f24080e7          	jalr	-220(ra) # 80001238 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000131c:	46a9                	li	a3,10
    8000131e:	6605                	lui	a2,0x1
    80001320:	00006597          	auipc	a1,0x6
    80001324:	ce058593          	addi	a1,a1,-800 # 80007000 <_trampoline>
    80001328:	04000537          	lui	a0,0x4000
    8000132c:	157d                	addi	a0,a0,-1
    8000132e:	0532                	slli	a0,a0,0xc
    80001330:	00000097          	auipc	ra,0x0
    80001334:	f08080e7          	jalr	-248(ra) # 80001238 <kvmmap>
}
    80001338:	60e2                	ld	ra,24(sp)
    8000133a:	6442                	ld	s0,16(sp)
    8000133c:	64a2                	ld	s1,8(sp)
    8000133e:	6105                	addi	sp,sp,32
    80001340:	8082                	ret

0000000080001342 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001342:	715d                	addi	sp,sp,-80
    80001344:	e486                	sd	ra,72(sp)
    80001346:	e0a2                	sd	s0,64(sp)
    80001348:	fc26                	sd	s1,56(sp)
    8000134a:	f84a                	sd	s2,48(sp)
    8000134c:	f44e                	sd	s3,40(sp)
    8000134e:	f052                	sd	s4,32(sp)
    80001350:	ec56                	sd	s5,24(sp)
    80001352:	e85a                	sd	s6,16(sp)
    80001354:	e45e                	sd	s7,8(sp)
    80001356:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001358:	03459793          	slli	a5,a1,0x34
    8000135c:	e795                	bnez	a5,80001388 <uvmunmap+0x46>
    8000135e:	8a2a                	mv	s4,a0
    80001360:	892e                	mv	s2,a1
    80001362:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001364:	0632                	slli	a2,a2,0xc
    80001366:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136c:	6b05                	lui	s6,0x1
    8000136e:	0735e863          	bltu	a1,s3,800013de <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001372:	60a6                	ld	ra,72(sp)
    80001374:	6406                	ld	s0,64(sp)
    80001376:	74e2                	ld	s1,56(sp)
    80001378:	7942                	ld	s2,48(sp)
    8000137a:	79a2                	ld	s3,40(sp)
    8000137c:	7a02                	ld	s4,32(sp)
    8000137e:	6ae2                	ld	s5,24(sp)
    80001380:	6b42                	ld	s6,16(sp)
    80001382:	6ba2                	ld	s7,8(sp)
    80001384:	6161                	addi	sp,sp,80
    80001386:	8082                	ret
    panic("uvmunmap: not aligned");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	d8050513          	addi	a0,a0,-640 # 80008108 <digits+0xb0>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	1b8080e7          	jalr	440(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001398:	00007517          	auipc	a0,0x7
    8000139c:	d8850513          	addi	a0,a0,-632 # 80008120 <digits+0xc8>
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	1a8080e7          	jalr	424(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    800013a8:	00007517          	auipc	a0,0x7
    800013ac:	d8850513          	addi	a0,a0,-632 # 80008130 <digits+0xd8>
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	198080e7          	jalr	408(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d9050513          	addi	a0,a0,-624 # 80008148 <digits+0xf0>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	188080e7          	jalr	392(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013c8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013ca:	0532                	slli	a0,a0,0xc
    800013cc:	fffff097          	auipc	ra,0xfffff
    800013d0:	6c4080e7          	jalr	1732(ra) # 80000a90 <kfree>
    *pte = 0;
    800013d4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d8:	995a                	add	s2,s2,s6
    800013da:	f9397ce3          	bgeu	s2,s3,80001372 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013de:	4601                	li	a2,0
    800013e0:	85ca                	mv	a1,s2
    800013e2:	8552                	mv	a0,s4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	c80080e7          	jalr	-896(ra) # 80001064 <walk>
    800013ec:	84aa                	mv	s1,a0
    800013ee:	d54d                	beqz	a0,80001398 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013f0:	6108                	ld	a0,0(a0)
    800013f2:	00157793          	andi	a5,a0,1
    800013f6:	dbcd                	beqz	a5,800013a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013f8:	3ff57793          	andi	a5,a0,1023
    800013fc:	fb778ee3          	beq	a5,s7,800013b8 <uvmunmap+0x76>
    if(do_free){
    80001400:	fc0a8ae3          	beqz	s5,800013d4 <uvmunmap+0x92>
    80001404:	b7d1                	j	800013c8 <uvmunmap+0x86>

0000000080001406 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001406:	1101                	addi	sp,sp,-32
    80001408:	ec06                	sd	ra,24(sp)
    8000140a:	e822                	sd	s0,16(sp)
    8000140c:	e426                	sd	s1,8(sp)
    8000140e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001410:	fffff097          	auipc	ra,0xfffff
    80001414:	77c080e7          	jalr	1916(ra) # 80000b8c <kalloc>
    80001418:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000141a:	c519                	beqz	a0,80001428 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000141c:	6605                	lui	a2,0x1
    8000141e:	4581                	li	a1,0
    80001420:	00000097          	auipc	ra,0x0
    80001424:	958080e7          	jalr	-1704(ra) # 80000d78 <memset>
  return pagetable;
}
    80001428:	8526                	mv	a0,s1
    8000142a:	60e2                	ld	ra,24(sp)
    8000142c:	6442                	ld	s0,16(sp)
    8000142e:	64a2                	ld	s1,8(sp)
    80001430:	6105                	addi	sp,sp,32
    80001432:	8082                	ret

0000000080001434 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001434:	7179                	addi	sp,sp,-48
    80001436:	f406                	sd	ra,40(sp)
    80001438:	f022                	sd	s0,32(sp)
    8000143a:	ec26                	sd	s1,24(sp)
    8000143c:	e84a                	sd	s2,16(sp)
    8000143e:	e44e                	sd	s3,8(sp)
    80001440:	e052                	sd	s4,0(sp)
    80001442:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001444:	6785                	lui	a5,0x1
    80001446:	04f67863          	bgeu	a2,a5,80001496 <uvminit+0x62>
    8000144a:	8a2a                	mv	s4,a0
    8000144c:	89ae                	mv	s3,a1
    8000144e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001450:	fffff097          	auipc	ra,0xfffff
    80001454:	73c080e7          	jalr	1852(ra) # 80000b8c <kalloc>
    80001458:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	91a080e7          	jalr	-1766(ra) # 80000d78 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001466:	4779                	li	a4,30
    80001468:	86ca                	mv	a3,s2
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	8552                	mv	a0,s4
    80001470:	00000097          	auipc	ra,0x0
    80001474:	d3a080e7          	jalr	-710(ra) # 800011aa <mappages>
  memmove(mem, src, sz);
    80001478:	8626                	mv	a2,s1
    8000147a:	85ce                	mv	a1,s3
    8000147c:	854a                	mv	a0,s2
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	95a080e7          	jalr	-1702(ra) # 80000dd8 <memmove>
}
    80001486:	70a2                	ld	ra,40(sp)
    80001488:	7402                	ld	s0,32(sp)
    8000148a:	64e2                	ld	s1,24(sp)
    8000148c:	6942                	ld	s2,16(sp)
    8000148e:	69a2                	ld	s3,8(sp)
    80001490:	6a02                	ld	s4,0(sp)
    80001492:	6145                	addi	sp,sp,48
    80001494:	8082                	ret
    panic("inituvm: more than a page");
    80001496:	00007517          	auipc	a0,0x7
    8000149a:	cca50513          	addi	a0,a0,-822 # 80008160 <digits+0x108>
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	0aa080e7          	jalr	170(ra) # 80000548 <panic>

00000000800014a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014a6:	1101                	addi	sp,sp,-32
    800014a8:	ec06                	sd	ra,24(sp)
    800014aa:	e822                	sd	s0,16(sp)
    800014ac:	e426                	sd	s1,8(sp)
    800014ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014b2:	00b67d63          	bgeu	a2,a1,800014cc <uvmdealloc+0x26>
    800014b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014b8:	6785                	lui	a5,0x1
    800014ba:	17fd                	addi	a5,a5,-1
    800014bc:	00f60733          	add	a4,a2,a5
    800014c0:	767d                	lui	a2,0xfffff
    800014c2:	8f71                	and	a4,a4,a2
    800014c4:	97ae                	add	a5,a5,a1
    800014c6:	8ff1                	and	a5,a5,a2
    800014c8:	00f76863          	bltu	a4,a5,800014d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014cc:	8526                	mv	a0,s1
    800014ce:	60e2                	ld	ra,24(sp)
    800014d0:	6442                	ld	s0,16(sp)
    800014d2:	64a2                	ld	s1,8(sp)
    800014d4:	6105                	addi	sp,sp,32
    800014d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014d8:	8f99                	sub	a5,a5,a4
    800014da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014dc:	4685                	li	a3,1
    800014de:	0007861b          	sext.w	a2,a5
    800014e2:	85ba                	mv	a1,a4
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	e5e080e7          	jalr	-418(ra) # 80001342 <uvmunmap>
    800014ec:	b7c5                	j	800014cc <uvmdealloc+0x26>

00000000800014ee <uvmalloc>:
  if(newsz < oldsz)
    800014ee:	0ab66163          	bltu	a2,a1,80001590 <uvmalloc+0xa2>
{
    800014f2:	7139                	addi	sp,sp,-64
    800014f4:	fc06                	sd	ra,56(sp)
    800014f6:	f822                	sd	s0,48(sp)
    800014f8:	f426                	sd	s1,40(sp)
    800014fa:	f04a                	sd	s2,32(sp)
    800014fc:	ec4e                	sd	s3,24(sp)
    800014fe:	e852                	sd	s4,16(sp)
    80001500:	e456                	sd	s5,8(sp)
    80001502:	0080                	addi	s0,sp,64
    80001504:	8aaa                	mv	s5,a0
    80001506:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001508:	6985                	lui	s3,0x1
    8000150a:	19fd                	addi	s3,s3,-1
    8000150c:	95ce                	add	a1,a1,s3
    8000150e:	79fd                	lui	s3,0xfffff
    80001510:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001514:	08c9f063          	bgeu	s3,a2,80001594 <uvmalloc+0xa6>
    80001518:	894e                	mv	s2,s3
    mem = kalloc();
    8000151a:	fffff097          	auipc	ra,0xfffff
    8000151e:	672080e7          	jalr	1650(ra) # 80000b8c <kalloc>
    80001522:	84aa                	mv	s1,a0
    if(mem == 0){
    80001524:	c51d                	beqz	a0,80001552 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001526:	6605                	lui	a2,0x1
    80001528:	4581                	li	a1,0
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	84e080e7          	jalr	-1970(ra) # 80000d78 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001532:	4779                	li	a4,30
    80001534:	86a6                	mv	a3,s1
    80001536:	6605                	lui	a2,0x1
    80001538:	85ca                	mv	a1,s2
    8000153a:	8556                	mv	a0,s5
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	c6e080e7          	jalr	-914(ra) # 800011aa <mappages>
    80001544:	e905                	bnez	a0,80001574 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001546:	6785                	lui	a5,0x1
    80001548:	993e                	add	s2,s2,a5
    8000154a:	fd4968e3          	bltu	s2,s4,8000151a <uvmalloc+0x2c>
  return newsz;
    8000154e:	8552                	mv	a0,s4
    80001550:	a809                	j	80001562 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001552:	864e                	mv	a2,s3
    80001554:	85ca                	mv	a1,s2
    80001556:	8556                	mv	a0,s5
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f4e080e7          	jalr	-178(ra) # 800014a6 <uvmdealloc>
      return 0;
    80001560:	4501                	li	a0,0
}
    80001562:	70e2                	ld	ra,56(sp)
    80001564:	7442                	ld	s0,48(sp)
    80001566:	74a2                	ld	s1,40(sp)
    80001568:	7902                	ld	s2,32(sp)
    8000156a:	69e2                	ld	s3,24(sp)
    8000156c:	6a42                	ld	s4,16(sp)
    8000156e:	6aa2                	ld	s5,8(sp)
    80001570:	6121                	addi	sp,sp,64
    80001572:	8082                	ret
      kfree(mem);
    80001574:	8526                	mv	a0,s1
    80001576:	fffff097          	auipc	ra,0xfffff
    8000157a:	51a080e7          	jalr	1306(ra) # 80000a90 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000157e:	864e                	mv	a2,s3
    80001580:	85ca                	mv	a1,s2
    80001582:	8556                	mv	a0,s5
    80001584:	00000097          	auipc	ra,0x0
    80001588:	f22080e7          	jalr	-222(ra) # 800014a6 <uvmdealloc>
      return 0;
    8000158c:	4501                	li	a0,0
    8000158e:	bfd1                	j	80001562 <uvmalloc+0x74>
    return oldsz;
    80001590:	852e                	mv	a0,a1
}
    80001592:	8082                	ret
  return newsz;
    80001594:	8532                	mv	a0,a2
    80001596:	b7f1                	j	80001562 <uvmalloc+0x74>

0000000080001598 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001598:	7179                	addi	sp,sp,-48
    8000159a:	f406                	sd	ra,40(sp)
    8000159c:	f022                	sd	s0,32(sp)
    8000159e:	ec26                	sd	s1,24(sp)
    800015a0:	e84a                	sd	s2,16(sp)
    800015a2:	e44e                	sd	s3,8(sp)
    800015a4:	e052                	sd	s4,0(sp)
    800015a6:	1800                	addi	s0,sp,48
    800015a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015aa:	84aa                	mv	s1,a0
    800015ac:	6905                	lui	s2,0x1
    800015ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b0:	4985                	li	s3,1
    800015b2:	a821                	j	800015ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015b6:	0532                	slli	a0,a0,0xc
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	fe0080e7          	jalr	-32(ra) # 80001598 <freewalk>
      pagetable[i] = 0;
    800015c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015c4:	04a1                	addi	s1,s1,8
    800015c6:	03248163          	beq	s1,s2,800015e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015cc:	00f57793          	andi	a5,a0,15
    800015d0:	ff3782e3          	beq	a5,s3,800015b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015d4:	8905                	andi	a0,a0,1
    800015d6:	d57d                	beqz	a0,800015c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015d8:	00007517          	auipc	a0,0x7
    800015dc:	ba850513          	addi	a0,a0,-1112 # 80008180 <digits+0x128>
    800015e0:	fffff097          	auipc	ra,0xfffff
    800015e4:	f68080e7          	jalr	-152(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015e8:	8552                	mv	a0,s4
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	4a6080e7          	jalr	1190(ra) # 80000a90 <kfree>
}
    800015f2:	70a2                	ld	ra,40(sp)
    800015f4:	7402                	ld	s0,32(sp)
    800015f6:	64e2                	ld	s1,24(sp)
    800015f8:	6942                	ld	s2,16(sp)
    800015fa:	69a2                	ld	s3,8(sp)
    800015fc:	6a02                	ld	s4,0(sp)
    800015fe:	6145                	addi	sp,sp,48
    80001600:	8082                	ret

0000000080001602 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001602:	1101                	addi	sp,sp,-32
    80001604:	ec06                	sd	ra,24(sp)
    80001606:	e822                	sd	s0,16(sp)
    80001608:	e426                	sd	s1,8(sp)
    8000160a:	1000                	addi	s0,sp,32
    8000160c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000160e:	e999                	bnez	a1,80001624 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001610:	8526                	mv	a0,s1
    80001612:	00000097          	auipc	ra,0x0
    80001616:	f86080e7          	jalr	-122(ra) # 80001598 <freewalk>
}
    8000161a:	60e2                	ld	ra,24(sp)
    8000161c:	6442                	ld	s0,16(sp)
    8000161e:	64a2                	ld	s1,8(sp)
    80001620:	6105                	addi	sp,sp,32
    80001622:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001624:	6605                	lui	a2,0x1
    80001626:	167d                	addi	a2,a2,-1
    80001628:	962e                	add	a2,a2,a1
    8000162a:	4685                	li	a3,1
    8000162c:	8231                	srli	a2,a2,0xc
    8000162e:	4581                	li	a1,0
    80001630:	00000097          	auipc	ra,0x0
    80001634:	d12080e7          	jalr	-750(ra) # 80001342 <uvmunmap>
    80001638:	bfe1                	j	80001610 <uvmfree+0xe>

000000008000163a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000163a:	c679                	beqz	a2,80001708 <uvmcopy+0xce>
{
    8000163c:	715d                	addi	sp,sp,-80
    8000163e:	e486                	sd	ra,72(sp)
    80001640:	e0a2                	sd	s0,64(sp)
    80001642:	fc26                	sd	s1,56(sp)
    80001644:	f84a                	sd	s2,48(sp)
    80001646:	f44e                	sd	s3,40(sp)
    80001648:	f052                	sd	s4,32(sp)
    8000164a:	ec56                	sd	s5,24(sp)
    8000164c:	e85a                	sd	s6,16(sp)
    8000164e:	e45e                	sd	s7,8(sp)
    80001650:	0880                	addi	s0,sp,80
    80001652:	8b2a                	mv	s6,a0
    80001654:	8aae                	mv	s5,a1
    80001656:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001658:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000165a:	4601                	li	a2,0
    8000165c:	85ce                	mv	a1,s3
    8000165e:	855a                	mv	a0,s6
    80001660:	00000097          	auipc	ra,0x0
    80001664:	a04080e7          	jalr	-1532(ra) # 80001064 <walk>
    80001668:	c531                	beqz	a0,800016b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000166a:	6118                	ld	a4,0(a0)
    8000166c:	00177793          	andi	a5,a4,1
    80001670:	cbb1                	beqz	a5,800016c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001672:	00a75593          	srli	a1,a4,0xa
    80001676:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000167a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000167e:	fffff097          	auipc	ra,0xfffff
    80001682:	50e080e7          	jalr	1294(ra) # 80000b8c <kalloc>
    80001686:	892a                	mv	s2,a0
    80001688:	c939                	beqz	a0,800016de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000168a:	6605                	lui	a2,0x1
    8000168c:	85de                	mv	a1,s7
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	74a080e7          	jalr	1866(ra) # 80000dd8 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001696:	8726                	mv	a4,s1
    80001698:	86ca                	mv	a3,s2
    8000169a:	6605                	lui	a2,0x1
    8000169c:	85ce                	mv	a1,s3
    8000169e:	8556                	mv	a0,s5
    800016a0:	00000097          	auipc	ra,0x0
    800016a4:	b0a080e7          	jalr	-1270(ra) # 800011aa <mappages>
    800016a8:	e515                	bnez	a0,800016d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016aa:	6785                	lui	a5,0x1
    800016ac:	99be                	add	s3,s3,a5
    800016ae:	fb49e6e3          	bltu	s3,s4,8000165a <uvmcopy+0x20>
    800016b2:	a081                	j	800016f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	adc50513          	addi	a0,a0,-1316 # 80008190 <digits+0x138>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e8c080e7          	jalr	-372(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016c4:	00007517          	auipc	a0,0x7
    800016c8:	aec50513          	addi	a0,a0,-1300 # 800081b0 <digits+0x158>
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	e7c080e7          	jalr	-388(ra) # 80000548 <panic>
      kfree(mem);
    800016d4:	854a                	mv	a0,s2
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	3ba080e7          	jalr	954(ra) # 80000a90 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016de:	4685                	li	a3,1
    800016e0:	00c9d613          	srli	a2,s3,0xc
    800016e4:	4581                	li	a1,0
    800016e6:	8556                	mv	a0,s5
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	c5a080e7          	jalr	-934(ra) # 80001342 <uvmunmap>
  return -1;
    800016f0:	557d                	li	a0,-1
}
    800016f2:	60a6                	ld	ra,72(sp)
    800016f4:	6406                	ld	s0,64(sp)
    800016f6:	74e2                	ld	s1,56(sp)
    800016f8:	7942                	ld	s2,48(sp)
    800016fa:	79a2                	ld	s3,40(sp)
    800016fc:	7a02                	ld	s4,32(sp)
    800016fe:	6ae2                	ld	s5,24(sp)
    80001700:	6b42                	ld	s6,16(sp)
    80001702:	6ba2                	ld	s7,8(sp)
    80001704:	6161                	addi	sp,sp,80
    80001706:	8082                	ret
  return 0;
    80001708:	4501                	li	a0,0
}
    8000170a:	8082                	ret

000000008000170c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000170c:	1141                	addi	sp,sp,-16
    8000170e:	e406                	sd	ra,8(sp)
    80001710:	e022                	sd	s0,0(sp)
    80001712:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001714:	4601                	li	a2,0
    80001716:	00000097          	auipc	ra,0x0
    8000171a:	94e080e7          	jalr	-1714(ra) # 80001064 <walk>
  if(pte == 0)
    8000171e:	c901                	beqz	a0,8000172e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001720:	611c                	ld	a5,0(a0)
    80001722:	9bbd                	andi	a5,a5,-17
    80001724:	e11c                	sd	a5,0(a0)
}
    80001726:	60a2                	ld	ra,8(sp)
    80001728:	6402                	ld	s0,0(sp)
    8000172a:	0141                	addi	sp,sp,16
    8000172c:	8082                	ret
    panic("uvmclear");
    8000172e:	00007517          	auipc	a0,0x7
    80001732:	aa250513          	addi	a0,a0,-1374 # 800081d0 <digits+0x178>
    80001736:	fffff097          	auipc	ra,0xfffff
    8000173a:	e12080e7          	jalr	-494(ra) # 80000548 <panic>

000000008000173e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000173e:	c6bd                	beqz	a3,800017ac <copyout+0x6e>
{
    80001740:	715d                	addi	sp,sp,-80
    80001742:	e486                	sd	ra,72(sp)
    80001744:	e0a2                	sd	s0,64(sp)
    80001746:	fc26                	sd	s1,56(sp)
    80001748:	f84a                	sd	s2,48(sp)
    8000174a:	f44e                	sd	s3,40(sp)
    8000174c:	f052                	sd	s4,32(sp)
    8000174e:	ec56                	sd	s5,24(sp)
    80001750:	e85a                	sd	s6,16(sp)
    80001752:	e45e                	sd	s7,8(sp)
    80001754:	e062                	sd	s8,0(sp)
    80001756:	0880                	addi	s0,sp,80
    80001758:	8b2a                	mv	s6,a0
    8000175a:	8c2e                	mv	s8,a1
    8000175c:	8a32                	mv	s4,a2
    8000175e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001760:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001762:	6a85                	lui	s5,0x1
    80001764:	a015                	j	80001788 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001766:	9562                	add	a0,a0,s8
    80001768:	0004861b          	sext.w	a2,s1
    8000176c:	85d2                	mv	a1,s4
    8000176e:	41250533          	sub	a0,a0,s2
    80001772:	fffff097          	auipc	ra,0xfffff
    80001776:	666080e7          	jalr	1638(ra) # 80000dd8 <memmove>

    len -= n;
    8000177a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000177e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001780:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001784:	02098263          	beqz	s3,800017a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001788:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000178c:	85ca                	mv	a1,s2
    8000178e:	855a                	mv	a0,s6
    80001790:	00000097          	auipc	ra,0x0
    80001794:	97a080e7          	jalr	-1670(ra) # 8000110a <walkaddr>
    if(pa0 == 0)
    80001798:	cd01                	beqz	a0,800017b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000179a:	418904b3          	sub	s1,s2,s8
    8000179e:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a0:	fc99f3e3          	bgeu	s3,s1,80001766 <copyout+0x28>
    800017a4:	84ce                	mv	s1,s3
    800017a6:	b7c1                	j	80001766 <copyout+0x28>
  }
  return 0;
    800017a8:	4501                	li	a0,0
    800017aa:	a021                	j	800017b2 <copyout+0x74>
    800017ac:	4501                	li	a0,0
}
    800017ae:	8082                	ret
      return -1;
    800017b0:	557d                	li	a0,-1
}
    800017b2:	60a6                	ld	ra,72(sp)
    800017b4:	6406                	ld	s0,64(sp)
    800017b6:	74e2                	ld	s1,56(sp)
    800017b8:	7942                	ld	s2,48(sp)
    800017ba:	79a2                	ld	s3,40(sp)
    800017bc:	7a02                	ld	s4,32(sp)
    800017be:	6ae2                	ld	s5,24(sp)
    800017c0:	6b42                	ld	s6,16(sp)
    800017c2:	6ba2                	ld	s7,8(sp)
    800017c4:	6c02                	ld	s8,0(sp)
    800017c6:	6161                	addi	sp,sp,80
    800017c8:	8082                	ret

00000000800017ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ca:	c6bd                	beqz	a3,80001838 <copyin+0x6e>
{
    800017cc:	715d                	addi	sp,sp,-80
    800017ce:	e486                	sd	ra,72(sp)
    800017d0:	e0a2                	sd	s0,64(sp)
    800017d2:	fc26                	sd	s1,56(sp)
    800017d4:	f84a                	sd	s2,48(sp)
    800017d6:	f44e                	sd	s3,40(sp)
    800017d8:	f052                	sd	s4,32(sp)
    800017da:	ec56                	sd	s5,24(sp)
    800017dc:	e85a                	sd	s6,16(sp)
    800017de:	e45e                	sd	s7,8(sp)
    800017e0:	e062                	sd	s8,0(sp)
    800017e2:	0880                	addi	s0,sp,80
    800017e4:	8b2a                	mv	s6,a0
    800017e6:	8a2e                	mv	s4,a1
    800017e8:	8c32                	mv	s8,a2
    800017ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ee:	6a85                	lui	s5,0x1
    800017f0:	a015                	j	80001814 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017f2:	9562                	add	a0,a0,s8
    800017f4:	0004861b          	sext.w	a2,s1
    800017f8:	412505b3          	sub	a1,a0,s2
    800017fc:	8552                	mv	a0,s4
    800017fe:	fffff097          	auipc	ra,0xfffff
    80001802:	5da080e7          	jalr	1498(ra) # 80000dd8 <memmove>

    len -= n;
    80001806:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000180a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000180c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001810:	02098263          	beqz	s3,80001834 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001814:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001818:	85ca                	mv	a1,s2
    8000181a:	855a                	mv	a0,s6
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	8ee080e7          	jalr	-1810(ra) # 8000110a <walkaddr>
    if(pa0 == 0)
    80001824:	cd01                	beqz	a0,8000183c <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001826:	418904b3          	sub	s1,s2,s8
    8000182a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000182c:	fc99f3e3          	bgeu	s3,s1,800017f2 <copyin+0x28>
    80001830:	84ce                	mv	s1,s3
    80001832:	b7c1                	j	800017f2 <copyin+0x28>
  }
  return 0;
    80001834:	4501                	li	a0,0
    80001836:	a021                	j	8000183e <copyin+0x74>
    80001838:	4501                	li	a0,0
}
    8000183a:	8082                	ret
      return -1;
    8000183c:	557d                	li	a0,-1
}
    8000183e:	60a6                	ld	ra,72(sp)
    80001840:	6406                	ld	s0,64(sp)
    80001842:	74e2                	ld	s1,56(sp)
    80001844:	7942                	ld	s2,48(sp)
    80001846:	79a2                	ld	s3,40(sp)
    80001848:	7a02                	ld	s4,32(sp)
    8000184a:	6ae2                	ld	s5,24(sp)
    8000184c:	6b42                	ld	s6,16(sp)
    8000184e:	6ba2                	ld	s7,8(sp)
    80001850:	6c02                	ld	s8,0(sp)
    80001852:	6161                	addi	sp,sp,80
    80001854:	8082                	ret

0000000080001856 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001856:	c6c5                	beqz	a3,800018fe <copyinstr+0xa8>
{
    80001858:	715d                	addi	sp,sp,-80
    8000185a:	e486                	sd	ra,72(sp)
    8000185c:	e0a2                	sd	s0,64(sp)
    8000185e:	fc26                	sd	s1,56(sp)
    80001860:	f84a                	sd	s2,48(sp)
    80001862:	f44e                	sd	s3,40(sp)
    80001864:	f052                	sd	s4,32(sp)
    80001866:	ec56                	sd	s5,24(sp)
    80001868:	e85a                	sd	s6,16(sp)
    8000186a:	e45e                	sd	s7,8(sp)
    8000186c:	0880                	addi	s0,sp,80
    8000186e:	8a2a                	mv	s4,a0
    80001870:	8b2e                	mv	s6,a1
    80001872:	8bb2                	mv	s7,a2
    80001874:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001876:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001878:	6985                	lui	s3,0x1
    8000187a:	a035                	j	800018a6 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000187c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001880:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001882:	0017b793          	seqz	a5,a5
    80001886:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000188a:	60a6                	ld	ra,72(sp)
    8000188c:	6406                	ld	s0,64(sp)
    8000188e:	74e2                	ld	s1,56(sp)
    80001890:	7942                	ld	s2,48(sp)
    80001892:	79a2                	ld	s3,40(sp)
    80001894:	7a02                	ld	s4,32(sp)
    80001896:	6ae2                	ld	s5,24(sp)
    80001898:	6b42                	ld	s6,16(sp)
    8000189a:	6ba2                	ld	s7,8(sp)
    8000189c:	6161                	addi	sp,sp,80
    8000189e:	8082                	ret
    srcva = va0 + PGSIZE;
    800018a0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018a4:	c8a9                	beqz	s1,800018f6 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018a6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018aa:	85ca                	mv	a1,s2
    800018ac:	8552                	mv	a0,s4
    800018ae:	00000097          	auipc	ra,0x0
    800018b2:	85c080e7          	jalr	-1956(ra) # 8000110a <walkaddr>
    if(pa0 == 0)
    800018b6:	c131                	beqz	a0,800018fa <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018b8:	41790833          	sub	a6,s2,s7
    800018bc:	984e                	add	a6,a6,s3
    if(n > max)
    800018be:	0104f363          	bgeu	s1,a6,800018c4 <copyinstr+0x6e>
    800018c2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018c4:	955e                	add	a0,a0,s7
    800018c6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ca:	fc080be3          	beqz	a6,800018a0 <copyinstr+0x4a>
    800018ce:	985a                	add	a6,a6,s6
    800018d0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018d2:	41650633          	sub	a2,a0,s6
    800018d6:	14fd                	addi	s1,s1,-1
    800018d8:	9b26                	add	s6,s6,s1
    800018da:	00f60733          	add	a4,a2,a5
    800018de:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800018e2:	df49                	beqz	a4,8000187c <copyinstr+0x26>
        *dst = *p;
    800018e4:	00e78023          	sb	a4,0(a5)
      --max;
    800018e8:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018ec:	0785                	addi	a5,a5,1
    while(n > 0){
    800018ee:	ff0796e3          	bne	a5,a6,800018da <copyinstr+0x84>
      dst++;
    800018f2:	8b42                	mv	s6,a6
    800018f4:	b775                	j	800018a0 <copyinstr+0x4a>
    800018f6:	4781                	li	a5,0
    800018f8:	b769                	j	80001882 <copyinstr+0x2c>
      return -1;
    800018fa:	557d                	li	a0,-1
    800018fc:	b779                	j	8000188a <copyinstr+0x34>
  int got_null = 0;
    800018fe:	4781                	li	a5,0
  if(got_null){
    80001900:	0017b793          	seqz	a5,a5
    80001904:	40f00533          	neg	a0,a5
}
    80001908:	8082                	ret

000000008000190a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000190a:	1101                	addi	sp,sp,-32
    8000190c:	ec06                	sd	ra,24(sp)
    8000190e:	e822                	sd	s0,16(sp)
    80001910:	e426                	sd	s1,8(sp)
    80001912:	1000                	addi	s0,sp,32
    80001914:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	2ec080e7          	jalr	748(ra) # 80000c02 <holding>
    8000191e:	c909                	beqz	a0,80001930 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001920:	749c                	ld	a5,40(s1)
    80001922:	00978f63          	beq	a5,s1,80001940 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001926:	60e2                	ld	ra,24(sp)
    80001928:	6442                	ld	s0,16(sp)
    8000192a:	64a2                	ld	s1,8(sp)
    8000192c:	6105                	addi	sp,sp,32
    8000192e:	8082                	ret
    panic("wakeup1");
    80001930:	00007517          	auipc	a0,0x7
    80001934:	8b050513          	addi	a0,a0,-1872 # 800081e0 <digits+0x188>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	c10080e7          	jalr	-1008(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001940:	4c98                	lw	a4,24(s1)
    80001942:	4785                	li	a5,1
    80001944:	fef711e3          	bne	a4,a5,80001926 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001948:	4789                	li	a5,2
    8000194a:	cc9c                	sw	a5,24(s1)
}
    8000194c:	bfe9                	j	80001926 <wakeup1+0x1c>

000000008000194e <procinit>:
{
    8000194e:	715d                	addi	sp,sp,-80
    80001950:	e486                	sd	ra,72(sp)
    80001952:	e0a2                	sd	s0,64(sp)
    80001954:	fc26                	sd	s1,56(sp)
    80001956:	f84a                	sd	s2,48(sp)
    80001958:	f44e                	sd	s3,40(sp)
    8000195a:	f052                	sd	s4,32(sp)
    8000195c:	ec56                	sd	s5,24(sp)
    8000195e:	e85a                	sd	s6,16(sp)
    80001960:	e45e                	sd	s7,8(sp)
    80001962:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001964:	00007597          	auipc	a1,0x7
    80001968:	88458593          	addi	a1,a1,-1916 # 800081e8 <digits+0x190>
    8000196c:	00010517          	auipc	a0,0x10
    80001970:	fe450513          	addi	a0,a0,-28 # 80011950 <pid_lock>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	278080e7          	jalr	632(ra) # 80000bec <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00010917          	auipc	s2,0x10
    80001980:	3ec90913          	addi	s2,s2,1004 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001984:	00007b97          	auipc	s7,0x7
    80001988:	86cb8b93          	addi	s7,s7,-1940 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000198c:	8b4a                	mv	s6,s2
    8000198e:	00006a97          	auipc	s5,0x6
    80001992:	672a8a93          	addi	s5,s5,1650 # 80008000 <etext>
    80001996:	040009b7          	lui	s3,0x4000
    8000199a:	19fd                	addi	s3,s3,-1
    8000199c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199e:	00016a17          	auipc	s4,0x16
    800019a2:	5caa0a13          	addi	s4,s4,1482 # 80017f68 <tickslock>
      initlock(&p->lock, "proc");
    800019a6:	85de                	mv	a1,s7
    800019a8:	854a                	mv	a0,s2
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	242080e7          	jalr	578(ra) # 80000bec <initlock>
      char *pa = kalloc();
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	1da080e7          	jalr	474(ra) # 80000b8c <kalloc>
    800019ba:	85aa                	mv	a1,a0
      if(pa == 0)
    800019bc:	c929                	beqz	a0,80001a0e <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019be:	416904b3          	sub	s1,s2,s6
    800019c2:	848d                	srai	s1,s1,0x3
    800019c4:	000ab783          	ld	a5,0(s5)
    800019c8:	02f484b3          	mul	s1,s1,a5
    800019cc:	2485                	addiw	s1,s1,1
    800019ce:	00d4949b          	slliw	s1,s1,0xd
    800019d2:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019d6:	4699                	li	a3,6
    800019d8:	6605                	lui	a2,0x1
    800019da:	8526                	mv	a0,s1
    800019dc:	00000097          	auipc	ra,0x0
    800019e0:	85c080e7          	jalr	-1956(ra) # 80001238 <kvmmap>
      p->kstack = va;
    800019e4:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e8:	18890913          	addi	s2,s2,392
    800019ec:	fb491de3          	bne	s2,s4,800019a6 <procinit+0x58>
  kvminithart();
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	650080e7          	jalr	1616(ra) # 80001040 <kvminithart>
}
    800019f8:	60a6                	ld	ra,72(sp)
    800019fa:	6406                	ld	s0,64(sp)
    800019fc:	74e2                	ld	s1,56(sp)
    800019fe:	7942                	ld	s2,48(sp)
    80001a00:	79a2                	ld	s3,40(sp)
    80001a02:	7a02                	ld	s4,32(sp)
    80001a04:	6ae2                	ld	s5,24(sp)
    80001a06:	6b42                	ld	s6,16(sp)
    80001a08:	6ba2                	ld	s7,8(sp)
    80001a0a:	6161                	addi	sp,sp,80
    80001a0c:	8082                	ret
        panic("kalloc");
    80001a0e:	00006517          	auipc	a0,0x6
    80001a12:	7ea50513          	addi	a0,a0,2026 # 800081f8 <digits+0x1a0>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	b32080e7          	jalr	-1230(ra) # 80000548 <panic>

0000000080001a1e <cpuid>:
{
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e422                	sd	s0,8(sp)
    80001a22:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a24:	8512                	mv	a0,tp
}
    80001a26:	2501                	sext.w	a0,a0
    80001a28:	6422                	ld	s0,8(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret

0000000080001a2e <mycpu>:
mycpu(void) {
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e422                	sd	s0,8(sp)
    80001a32:	0800                	addi	s0,sp,16
    80001a34:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a36:	2781                	sext.w	a5,a5
    80001a38:	079e                	slli	a5,a5,0x7
}
    80001a3a:	00010517          	auipc	a0,0x10
    80001a3e:	f2e50513          	addi	a0,a0,-210 # 80011968 <cpus>
    80001a42:	953e                	add	a0,a0,a5
    80001a44:	6422                	ld	s0,8(sp)
    80001a46:	0141                	addi	sp,sp,16
    80001a48:	8082                	ret

0000000080001a4a <myproc>:
myproc(void) {
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	1000                	addi	s0,sp,32
  push_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	1dc080e7          	jalr	476(ra) # 80000c30 <push_off>
    80001a5c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a5e:	2781                	sext.w	a5,a5
    80001a60:	079e                	slli	a5,a5,0x7
    80001a62:	00010717          	auipc	a4,0x10
    80001a66:	eee70713          	addi	a4,a4,-274 # 80011950 <pid_lock>
    80001a6a:	97ba                	add	a5,a5,a4
    80001a6c:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	262080e7          	jalr	610(ra) # 80000cd0 <pop_off>
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6105                	addi	sp,sp,32
    80001a80:	8082                	ret

0000000080001a82 <forkret>:
{
    80001a82:	1141                	addi	sp,sp,-16
    80001a84:	e406                	sd	ra,8(sp)
    80001a86:	e022                	sd	s0,0(sp)
    80001a88:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a8a:	00000097          	auipc	ra,0x0
    80001a8e:	fc0080e7          	jalr	-64(ra) # 80001a4a <myproc>
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	29e080e7          	jalr	670(ra) # 80000d30 <release>
  if (first) {
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	da67a783          	lw	a5,-602(a5) # 80008840 <first.1673>
    80001aa2:	eb89                	bnez	a5,80001ab4 <forkret+0x32>
  usertrapret();
    80001aa4:	00001097          	auipc	ra,0x1
    80001aa8:	c72080e7          	jalr	-910(ra) # 80002716 <usertrapret>
}
    80001aac:	60a2                	ld	ra,8(sp)
    80001aae:	6402                	ld	s0,0(sp)
    80001ab0:	0141                	addi	sp,sp,16
    80001ab2:	8082                	ret
    first = 0;
    80001ab4:	00007797          	auipc	a5,0x7
    80001ab8:	d807a623          	sw	zero,-628(a5) # 80008840 <first.1673>
    fsinit(ROOTDEV);
    80001abc:	4505                	li	a0,1
    80001abe:	00002097          	auipc	ra,0x2
    80001ac2:	a82080e7          	jalr	-1406(ra) # 80003540 <fsinit>
    80001ac6:	bff9                	j	80001aa4 <forkret+0x22>

0000000080001ac8 <allocpid>:
allocpid() {
    80001ac8:	1101                	addi	sp,sp,-32
    80001aca:	ec06                	sd	ra,24(sp)
    80001acc:	e822                	sd	s0,16(sp)
    80001ace:	e426                	sd	s1,8(sp)
    80001ad0:	e04a                	sd	s2,0(sp)
    80001ad2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ad4:	00010917          	auipc	s2,0x10
    80001ad8:	e7c90913          	addi	s2,s2,-388 # 80011950 <pid_lock>
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	19e080e7          	jalr	414(ra) # 80000c7c <acquire>
  pid = nextpid;
    80001ae6:	00007797          	auipc	a5,0x7
    80001aea:	d5e78793          	addi	a5,a5,-674 # 80008844 <nextpid>
    80001aee:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001af0:	0014871b          	addiw	a4,s1,1
    80001af4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001af6:	854a                	mv	a0,s2
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	238080e7          	jalr	568(ra) # 80000d30 <release>
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6902                	ld	s2,0(sp)
    80001b0a:	6105                	addi	sp,sp,32
    80001b0c:	8082                	ret

0000000080001b0e <proc_pagetable>:
{
    80001b0e:	1101                	addi	sp,sp,-32
    80001b10:	ec06                	sd	ra,24(sp)
    80001b12:	e822                	sd	s0,16(sp)
    80001b14:	e426                	sd	s1,8(sp)
    80001b16:	e04a                	sd	s2,0(sp)
    80001b18:	1000                	addi	s0,sp,32
    80001b1a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	8ea080e7          	jalr	-1814(ra) # 80001406 <uvmcreate>
    80001b24:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b26:	c121                	beqz	a0,80001b66 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b28:	4729                	li	a4,10
    80001b2a:	00005697          	auipc	a3,0x5
    80001b2e:	4d668693          	addi	a3,a3,1238 # 80007000 <_trampoline>
    80001b32:	6605                	lui	a2,0x1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	66e080e7          	jalr	1646(ra) # 800011aa <mappages>
    80001b44:	02054863          	bltz	a0,80001b74 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b48:	4719                	li	a4,6
    80001b4a:	05893683          	ld	a3,88(s2)
    80001b4e:	6605                	lui	a2,0x1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	650080e7          	jalr	1616(ra) # 800011aa <mappages>
    80001b62:	02054163          	bltz	a0,80001b84 <proc_pagetable+0x76>
}
    80001b66:	8526                	mv	a0,s1
    80001b68:	60e2                	ld	ra,24(sp)
    80001b6a:	6442                	ld	s0,16(sp)
    80001b6c:	64a2                	ld	s1,8(sp)
    80001b6e:	6902                	ld	s2,0(sp)
    80001b70:	6105                	addi	sp,sp,32
    80001b72:	8082                	ret
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a8a080e7          	jalr	-1398(ra) # 80001602 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	b7d5                	j	80001b66 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b84:	4681                	li	a3,0
    80001b86:	4605                	li	a2,1
    80001b88:	040005b7          	lui	a1,0x4000
    80001b8c:	15fd                	addi	a1,a1,-1
    80001b8e:	05b2                	slli	a1,a1,0xc
    80001b90:	8526                	mv	a0,s1
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	7b0080e7          	jalr	1968(ra) # 80001342 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b9a:	4581                	li	a1,0
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	a64080e7          	jalr	-1436(ra) # 80001602 <uvmfree>
    return 0;
    80001ba6:	4481                	li	s1,0
    80001ba8:	bf7d                	j	80001b66 <proc_pagetable+0x58>

0000000080001baa <proc_freepagetable>:
{
    80001baa:	1101                	addi	sp,sp,-32
    80001bac:	ec06                	sd	ra,24(sp)
    80001bae:	e822                	sd	s0,16(sp)
    80001bb0:	e426                	sd	s1,8(sp)
    80001bb2:	e04a                	sd	s2,0(sp)
    80001bb4:	1000                	addi	s0,sp,32
    80001bb6:	84aa                	mv	s1,a0
    80001bb8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bba:	4681                	li	a3,0
    80001bbc:	4605                	li	a2,1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	77c080e7          	jalr	1916(ra) # 80001342 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bce:	4681                	li	a3,0
    80001bd0:	4605                	li	a2,1
    80001bd2:	020005b7          	lui	a1,0x2000
    80001bd6:	15fd                	addi	a1,a1,-1
    80001bd8:	05b6                	slli	a1,a1,0xd
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	766080e7          	jalr	1894(ra) # 80001342 <uvmunmap>
  uvmfree(pagetable, sz);
    80001be4:	85ca                	mv	a1,s2
    80001be6:	8526                	mv	a0,s1
    80001be8:	00000097          	auipc	ra,0x0
    80001bec:	a1a080e7          	jalr	-1510(ra) # 80001602 <uvmfree>
}
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6902                	ld	s2,0(sp)
    80001bf8:	6105                	addi	sp,sp,32
    80001bfa:	8082                	ret

0000000080001bfc <freeproc>:
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	1000                	addi	s0,sp,32
    80001c06:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c08:	6d28                	ld	a0,88(a0)
    80001c0a:	c509                	beqz	a0,80001c14 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	e84080e7          	jalr	-380(ra) # 80000a90 <kfree>
  p->trapframe = 0;
    80001c14:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c18:	68a8                	ld	a0,80(s1)
    80001c1a:	c511                	beqz	a0,80001c26 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c1c:	64ac                	ld	a1,72(s1)
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	f8c080e7          	jalr	-116(ra) # 80001baa <proc_freepagetable>
  p->pagetable = 0;
    80001c26:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c2a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c2e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c32:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c36:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c3a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c3e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c42:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c46:	0004ac23          	sw	zero,24(s1)
  if (p->alarm_trapframe)
    80001c4a:	1804b503          	ld	a0,384(s1)
    80001c4e:	c509                	beqz	a0,80001c58 <freeproc+0x5c>
    kfree((void*)p->alarm_trapframe);
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	e40080e7          	jalr	-448(ra) # 80000a90 <kfree>
  p->alarm_trapframe = 0;
    80001c58:	1804b023          	sd	zero,384(s1)
  p->is_alarming = 0;
    80001c5c:	1604ae23          	sw	zero,380(s1)
  p->alarm_interval = 0;
    80001c60:	1604a423          	sw	zero,360(s1)
  p->alarm_handler = 0;
    80001c64:	1604b823          	sd	zero,368(s1)
  p->ticks_count = 0;
    80001c68:	1604ac23          	sw	zero,376(s1)
}
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6105                	addi	sp,sp,32
    80001c74:	8082                	ret

0000000080001c76 <allocproc>:
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	e04a                	sd	s2,0(sp)
    80001c80:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c82:	00010497          	auipc	s1,0x10
    80001c86:	0e648493          	addi	s1,s1,230 # 80011d68 <proc>
    80001c8a:	00016917          	auipc	s2,0x16
    80001c8e:	2de90913          	addi	s2,s2,734 # 80017f68 <tickslock>
    acquire(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	fe8080e7          	jalr	-24(ra) # 80000c7c <acquire>
    if(p->state == UNUSED) {
    80001c9c:	4c9c                	lw	a5,24(s1)
    80001c9e:	cf81                	beqz	a5,80001cb6 <allocproc+0x40>
      release(&p->lock);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	08e080e7          	jalr	142(ra) # 80000d30 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001caa:	18848493          	addi	s1,s1,392
    80001cae:	ff2492e3          	bne	s1,s2,80001c92 <allocproc+0x1c>
  return 0;
    80001cb2:	4481                	li	s1,0
    80001cb4:	a0bd                	j	80001d22 <allocproc+0xac>
  p->pid = allocpid();
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	e12080e7          	jalr	-494(ra) # 80001ac8 <allocpid>
    80001cbe:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	ecc080e7          	jalr	-308(ra) # 80000b8c <kalloc>
    80001cc8:	892a                	mv	s2,a0
    80001cca:	eca8                	sd	a0,88(s1)
    80001ccc:	c135                	beqz	a0,80001d30 <allocproc+0xba>
  if ((p->alarm_trapframe = (struct trapframe*)kalloc()) == 0) {
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	ebe080e7          	jalr	-322(ra) # 80000b8c <kalloc>
    80001cd6:	892a                	mv	s2,a0
    80001cd8:	18a4b023          	sd	a0,384(s1)
    80001cdc:	c12d                	beqz	a0,80001d3e <allocproc+0xc8>
  p->is_alarming = 0;
    80001cde:	1604ae23          	sw	zero,380(s1)
  p->alarm_interval = 0;
    80001ce2:	1604a423          	sw	zero,360(s1)
  p->alarm_handler = 0;
    80001ce6:	1604b823          	sd	zero,368(s1)
  p->ticks_count = 0;
    80001cea:	1604ac23          	sw	zero,376(s1)
  p->pagetable = proc_pagetable(p);
    80001cee:	8526                	mv	a0,s1
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	e1e080e7          	jalr	-482(ra) # 80001b0e <proc_pagetable>
    80001cf8:	892a                	mv	s2,a0
    80001cfa:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cfc:	cd29                	beqz	a0,80001d56 <allocproc+0xe0>
  memset(&p->context, 0, sizeof(p->context));
    80001cfe:	07000613          	li	a2,112
    80001d02:	4581                	li	a1,0
    80001d04:	06048513          	addi	a0,s1,96
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	070080e7          	jalr	112(ra) # 80000d78 <memset>
  p->context.ra = (uint64)forkret;
    80001d10:	00000797          	auipc	a5,0x0
    80001d14:	d7278793          	addi	a5,a5,-654 # 80001a82 <forkret>
    80001d18:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d1a:	60bc                	ld	a5,64(s1)
    80001d1c:	6705                	lui	a4,0x1
    80001d1e:	97ba                	add	a5,a5,a4
    80001d20:	f4bc                	sd	a5,104(s1)
}
    80001d22:	8526                	mv	a0,s1
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6902                	ld	s2,0(sp)
    80001d2c:	6105                	addi	sp,sp,32
    80001d2e:	8082                	ret
    release(&p->lock);
    80001d30:	8526                	mv	a0,s1
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	ffe080e7          	jalr	-2(ra) # 80000d30 <release>
    return 0;
    80001d3a:	84ca                	mv	s1,s2
    80001d3c:	b7dd                	j	80001d22 <allocproc+0xac>
    freeproc(p);
    80001d3e:	8526                	mv	a0,s1
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	ebc080e7          	jalr	-324(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	fe6080e7          	jalr	-26(ra) # 80000d30 <release>
    return 0;
    80001d52:	84ca                	mv	s1,s2
    80001d54:	b7f9                	j	80001d22 <allocproc+0xac>
    freeproc(p);
    80001d56:	8526                	mv	a0,s1
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	ea4080e7          	jalr	-348(ra) # 80001bfc <freeproc>
    release(&p->lock);
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	fce080e7          	jalr	-50(ra) # 80000d30 <release>
    return 0;
    80001d6a:	84ca                	mv	s1,s2
    80001d6c:	bf5d                	j	80001d22 <allocproc+0xac>

0000000080001d6e <userinit>:
{
    80001d6e:	1101                	addi	sp,sp,-32
    80001d70:	ec06                	sd	ra,24(sp)
    80001d72:	e822                	sd	s0,16(sp)
    80001d74:	e426                	sd	s1,8(sp)
    80001d76:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	efe080e7          	jalr	-258(ra) # 80001c76 <allocproc>
    80001d80:	84aa                	mv	s1,a0
  initproc = p;
    80001d82:	00007797          	auipc	a5,0x7
    80001d86:	28a7bb23          	sd	a0,662(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d8a:	03400613          	li	a2,52
    80001d8e:	00007597          	auipc	a1,0x7
    80001d92:	ac258593          	addi	a1,a1,-1342 # 80008850 <initcode>
    80001d96:	6928                	ld	a0,80(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	69c080e7          	jalr	1692(ra) # 80001434 <uvminit>
  p->sz = PGSIZE;
    80001da0:	6785                	lui	a5,0x1
    80001da2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001da4:	6cb8                	ld	a4,88(s1)
    80001da6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001daa:	6cb8                	ld	a4,88(s1)
    80001dac:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dae:	4641                	li	a2,16
    80001db0:	00006597          	auipc	a1,0x6
    80001db4:	45058593          	addi	a1,a1,1104 # 80008200 <digits+0x1a8>
    80001db8:	15848513          	addi	a0,s1,344
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	112080e7          	jalr	274(ra) # 80000ece <safestrcpy>
  p->cwd = namei("/");
    80001dc4:	00006517          	auipc	a0,0x6
    80001dc8:	44c50513          	addi	a0,a0,1100 # 80008210 <digits+0x1b8>
    80001dcc:	00002097          	auipc	ra,0x2
    80001dd0:	19c080e7          	jalr	412(ra) # 80003f68 <namei>
    80001dd4:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dd8:	4789                	li	a5,2
    80001dda:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	f52080e7          	jalr	-174(ra) # 80000d30 <release>
}
    80001de6:	60e2                	ld	ra,24(sp)
    80001de8:	6442                	ld	s0,16(sp)
    80001dea:	64a2                	ld	s1,8(sp)
    80001dec:	6105                	addi	sp,sp,32
    80001dee:	8082                	ret

0000000080001df0 <growproc>:
{
    80001df0:	1101                	addi	sp,sp,-32
    80001df2:	ec06                	sd	ra,24(sp)
    80001df4:	e822                	sd	s0,16(sp)
    80001df6:	e426                	sd	s1,8(sp)
    80001df8:	e04a                	sd	s2,0(sp)
    80001dfa:	1000                	addi	s0,sp,32
    80001dfc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	c4c080e7          	jalr	-948(ra) # 80001a4a <myproc>
    80001e06:	892a                	mv	s2,a0
  sz = p->sz;
    80001e08:	652c                	ld	a1,72(a0)
    80001e0a:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e0e:	00904f63          	bgtz	s1,80001e2c <growproc+0x3c>
  } else if(n < 0){
    80001e12:	0204cc63          	bltz	s1,80001e4a <growproc+0x5a>
  p->sz = sz;
    80001e16:	1602                	slli	a2,a2,0x20
    80001e18:	9201                	srli	a2,a2,0x20
    80001e1a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e1e:	4501                	li	a0,0
}
    80001e20:	60e2                	ld	ra,24(sp)
    80001e22:	6442                	ld	s0,16(sp)
    80001e24:	64a2                	ld	s1,8(sp)
    80001e26:	6902                	ld	s2,0(sp)
    80001e28:	6105                	addi	sp,sp,32
    80001e2a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e2c:	9e25                	addw	a2,a2,s1
    80001e2e:	1602                	slli	a2,a2,0x20
    80001e30:	9201                	srli	a2,a2,0x20
    80001e32:	1582                	slli	a1,a1,0x20
    80001e34:	9181                	srli	a1,a1,0x20
    80001e36:	6928                	ld	a0,80(a0)
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	6b6080e7          	jalr	1718(ra) # 800014ee <uvmalloc>
    80001e40:	0005061b          	sext.w	a2,a0
    80001e44:	fa69                	bnez	a2,80001e16 <growproc+0x26>
      return -1;
    80001e46:	557d                	li	a0,-1
    80001e48:	bfe1                	j	80001e20 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e4a:	9e25                	addw	a2,a2,s1
    80001e4c:	1602                	slli	a2,a2,0x20
    80001e4e:	9201                	srli	a2,a2,0x20
    80001e50:	1582                	slli	a1,a1,0x20
    80001e52:	9181                	srli	a1,a1,0x20
    80001e54:	6928                	ld	a0,80(a0)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	650080e7          	jalr	1616(ra) # 800014a6 <uvmdealloc>
    80001e5e:	0005061b          	sext.w	a2,a0
    80001e62:	bf55                	j	80001e16 <growproc+0x26>

0000000080001e64 <fork>:
{
    80001e64:	7179                	addi	sp,sp,-48
    80001e66:	f406                	sd	ra,40(sp)
    80001e68:	f022                	sd	s0,32(sp)
    80001e6a:	ec26                	sd	s1,24(sp)
    80001e6c:	e84a                	sd	s2,16(sp)
    80001e6e:	e44e                	sd	s3,8(sp)
    80001e70:	e052                	sd	s4,0(sp)
    80001e72:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	bd6080e7          	jalr	-1066(ra) # 80001a4a <myproc>
    80001e7c:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e7e:	00000097          	auipc	ra,0x0
    80001e82:	df8080e7          	jalr	-520(ra) # 80001c76 <allocproc>
    80001e86:	c175                	beqz	a0,80001f6a <fork+0x106>
    80001e88:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e8a:	04893603          	ld	a2,72(s2)
    80001e8e:	692c                	ld	a1,80(a0)
    80001e90:	05093503          	ld	a0,80(s2)
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	7a6080e7          	jalr	1958(ra) # 8000163a <uvmcopy>
    80001e9c:	04054863          	bltz	a0,80001eec <fork+0x88>
  np->sz = p->sz;
    80001ea0:	04893783          	ld	a5,72(s2)
    80001ea4:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001ea8:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001eac:	05893683          	ld	a3,88(s2)
    80001eb0:	87b6                	mv	a5,a3
    80001eb2:	0589b703          	ld	a4,88(s3)
    80001eb6:	12068693          	addi	a3,a3,288
    80001eba:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ebe:	6788                	ld	a0,8(a5)
    80001ec0:	6b8c                	ld	a1,16(a5)
    80001ec2:	6f90                	ld	a2,24(a5)
    80001ec4:	01073023          	sd	a6,0(a4)
    80001ec8:	e708                	sd	a0,8(a4)
    80001eca:	eb0c                	sd	a1,16(a4)
    80001ecc:	ef10                	sd	a2,24(a4)
    80001ece:	02078793          	addi	a5,a5,32
    80001ed2:	02070713          	addi	a4,a4,32
    80001ed6:	fed792e3          	bne	a5,a3,80001eba <fork+0x56>
  np->trapframe->a0 = 0;
    80001eda:	0589b783          	ld	a5,88(s3)
    80001ede:	0607b823          	sd	zero,112(a5)
    80001ee2:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ee6:	15000a13          	li	s4,336
    80001eea:	a03d                	j	80001f18 <fork+0xb4>
    freeproc(np);
    80001eec:	854e                	mv	a0,s3
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	d0e080e7          	jalr	-754(ra) # 80001bfc <freeproc>
    release(&np->lock);
    80001ef6:	854e                	mv	a0,s3
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	e38080e7          	jalr	-456(ra) # 80000d30 <release>
    return -1;
    80001f00:	54fd                	li	s1,-1
    80001f02:	a899                	j	80001f58 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f04:	00002097          	auipc	ra,0x2
    80001f08:	6f0080e7          	jalr	1776(ra) # 800045f4 <filedup>
    80001f0c:	009987b3          	add	a5,s3,s1
    80001f10:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f12:	04a1                	addi	s1,s1,8
    80001f14:	01448763          	beq	s1,s4,80001f22 <fork+0xbe>
    if(p->ofile[i])
    80001f18:	009907b3          	add	a5,s2,s1
    80001f1c:	6388                	ld	a0,0(a5)
    80001f1e:	f17d                	bnez	a0,80001f04 <fork+0xa0>
    80001f20:	bfcd                	j	80001f12 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f22:	15093503          	ld	a0,336(s2)
    80001f26:	00002097          	auipc	ra,0x2
    80001f2a:	854080e7          	jalr	-1964(ra) # 8000377a <idup>
    80001f2e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f32:	4641                	li	a2,16
    80001f34:	15890593          	addi	a1,s2,344
    80001f38:	15898513          	addi	a0,s3,344
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	f92080e7          	jalr	-110(ra) # 80000ece <safestrcpy>
  pid = np->pid;
    80001f44:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f48:	4789                	li	a5,2
    80001f4a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f4e:	854e                	mv	a0,s3
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	de0080e7          	jalr	-544(ra) # 80000d30 <release>
}
    80001f58:	8526                	mv	a0,s1
    80001f5a:	70a2                	ld	ra,40(sp)
    80001f5c:	7402                	ld	s0,32(sp)
    80001f5e:	64e2                	ld	s1,24(sp)
    80001f60:	6942                	ld	s2,16(sp)
    80001f62:	69a2                	ld	s3,8(sp)
    80001f64:	6a02                	ld	s4,0(sp)
    80001f66:	6145                	addi	sp,sp,48
    80001f68:	8082                	ret
    return -1;
    80001f6a:	54fd                	li	s1,-1
    80001f6c:	b7f5                	j	80001f58 <fork+0xf4>

0000000080001f6e <reparent>:
{
    80001f6e:	7179                	addi	sp,sp,-48
    80001f70:	f406                	sd	ra,40(sp)
    80001f72:	f022                	sd	s0,32(sp)
    80001f74:	ec26                	sd	s1,24(sp)
    80001f76:	e84a                	sd	s2,16(sp)
    80001f78:	e44e                	sd	s3,8(sp)
    80001f7a:	e052                	sd	s4,0(sp)
    80001f7c:	1800                	addi	s0,sp,48
    80001f7e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f80:	00010497          	auipc	s1,0x10
    80001f84:	de848493          	addi	s1,s1,-536 # 80011d68 <proc>
      pp->parent = initproc;
    80001f88:	00007a17          	auipc	s4,0x7
    80001f8c:	090a0a13          	addi	s4,s4,144 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f90:	00016997          	auipc	s3,0x16
    80001f94:	fd898993          	addi	s3,s3,-40 # 80017f68 <tickslock>
    80001f98:	a029                	j	80001fa2 <reparent+0x34>
    80001f9a:	18848493          	addi	s1,s1,392
    80001f9e:	03348363          	beq	s1,s3,80001fc4 <reparent+0x56>
    if(pp->parent == p){
    80001fa2:	709c                	ld	a5,32(s1)
    80001fa4:	ff279be3          	bne	a5,s2,80001f9a <reparent+0x2c>
      acquire(&pp->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	cd2080e7          	jalr	-814(ra) # 80000c7c <acquire>
      pp->parent = initproc;
    80001fb2:	000a3783          	ld	a5,0(s4)
    80001fb6:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	d76080e7          	jalr	-650(ra) # 80000d30 <release>
    80001fc2:	bfe1                	j	80001f9a <reparent+0x2c>
}
    80001fc4:	70a2                	ld	ra,40(sp)
    80001fc6:	7402                	ld	s0,32(sp)
    80001fc8:	64e2                	ld	s1,24(sp)
    80001fca:	6942                	ld	s2,16(sp)
    80001fcc:	69a2                	ld	s3,8(sp)
    80001fce:	6a02                	ld	s4,0(sp)
    80001fd0:	6145                	addi	sp,sp,48
    80001fd2:	8082                	ret

0000000080001fd4 <scheduler>:
{
    80001fd4:	715d                	addi	sp,sp,-80
    80001fd6:	e486                	sd	ra,72(sp)
    80001fd8:	e0a2                	sd	s0,64(sp)
    80001fda:	fc26                	sd	s1,56(sp)
    80001fdc:	f84a                	sd	s2,48(sp)
    80001fde:	f44e                	sd	s3,40(sp)
    80001fe0:	f052                	sd	s4,32(sp)
    80001fe2:	ec56                	sd	s5,24(sp)
    80001fe4:	e85a                	sd	s6,16(sp)
    80001fe6:	e45e                	sd	s7,8(sp)
    80001fe8:	e062                	sd	s8,0(sp)
    80001fea:	0880                	addi	s0,sp,80
    80001fec:	8792                	mv	a5,tp
  int id = r_tp();
    80001fee:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ff0:	00779b13          	slli	s6,a5,0x7
    80001ff4:	00010717          	auipc	a4,0x10
    80001ff8:	95c70713          	addi	a4,a4,-1700 # 80011950 <pid_lock>
    80001ffc:	975a                	add	a4,a4,s6
    80001ffe:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002002:	00010717          	auipc	a4,0x10
    80002006:	96e70713          	addi	a4,a4,-1682 # 80011970 <cpus+0x8>
    8000200a:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    8000200c:	4c0d                	li	s8,3
        c->proc = p;
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	00010a17          	auipc	s4,0x10
    80002014:	940a0a13          	addi	s4,s4,-1728 # 80011950 <pid_lock>
    80002018:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000201a:	00016997          	auipc	s3,0x16
    8000201e:	f4e98993          	addi	s3,s3,-178 # 80017f68 <tickslock>
        found = 1;
    80002022:	4b85                	li	s7,1
    80002024:	a899                	j	8000207a <scheduler+0xa6>
        p->state = RUNNING;
    80002026:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    8000202a:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    8000202e:	06048593          	addi	a1,s1,96
    80002032:	855a                	mv	a0,s6
    80002034:	00000097          	auipc	ra,0x0
    80002038:	638080e7          	jalr	1592(ra) # 8000266c <swtch>
        c->proc = 0;
    8000203c:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002040:	8ade                	mv	s5,s7
      release(&p->lock);
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	cec080e7          	jalr	-788(ra) # 80000d30 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000204c:	18848493          	addi	s1,s1,392
    80002050:	01348b63          	beq	s1,s3,80002066 <scheduler+0x92>
      acquire(&p->lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c26080e7          	jalr	-986(ra) # 80000c7c <acquire>
      if(p->state == RUNNABLE) {
    8000205e:	4c9c                	lw	a5,24(s1)
    80002060:	ff2791e3          	bne	a5,s2,80002042 <scheduler+0x6e>
    80002064:	b7c9                	j	80002026 <scheduler+0x52>
    if(found == 0) {
    80002066:	000a9a63          	bnez	s5,8000207a <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000206a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000206e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002072:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002076:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000207a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000207e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002082:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002086:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002088:	00010497          	auipc	s1,0x10
    8000208c:	ce048493          	addi	s1,s1,-800 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002090:	4909                	li	s2,2
    80002092:	b7c9                	j	80002054 <scheduler+0x80>

0000000080002094 <sched>:
{
    80002094:	7179                	addi	sp,sp,-48
    80002096:	f406                	sd	ra,40(sp)
    80002098:	f022                	sd	s0,32(sp)
    8000209a:	ec26                	sd	s1,24(sp)
    8000209c:	e84a                	sd	s2,16(sp)
    8000209e:	e44e                	sd	s3,8(sp)
    800020a0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	9a8080e7          	jalr	-1624(ra) # 80001a4a <myproc>
    800020aa:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	b56080e7          	jalr	-1194(ra) # 80000c02 <holding>
    800020b4:	c93d                	beqz	a0,8000212a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020b8:	2781                	sext.w	a5,a5
    800020ba:	079e                	slli	a5,a5,0x7
    800020bc:	00010717          	auipc	a4,0x10
    800020c0:	89470713          	addi	a4,a4,-1900 # 80011950 <pid_lock>
    800020c4:	97ba                	add	a5,a5,a4
    800020c6:	0907a703          	lw	a4,144(a5)
    800020ca:	4785                	li	a5,1
    800020cc:	06f71763          	bne	a4,a5,8000213a <sched+0xa6>
  if(p->state == RUNNING)
    800020d0:	4c98                	lw	a4,24(s1)
    800020d2:	478d                	li	a5,3
    800020d4:	06f70b63          	beq	a4,a5,8000214a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020dc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020de:	efb5                	bnez	a5,8000215a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020e0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020e2:	00010917          	auipc	s2,0x10
    800020e6:	86e90913          	addi	s2,s2,-1938 # 80011950 <pid_lock>
    800020ea:	2781                	sext.w	a5,a5
    800020ec:	079e                	slli	a5,a5,0x7
    800020ee:	97ca                	add	a5,a5,s2
    800020f0:	0947a983          	lw	s3,148(a5)
    800020f4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020f6:	2781                	sext.w	a5,a5
    800020f8:	079e                	slli	a5,a5,0x7
    800020fa:	00010597          	auipc	a1,0x10
    800020fe:	87658593          	addi	a1,a1,-1930 # 80011970 <cpus+0x8>
    80002102:	95be                	add	a1,a1,a5
    80002104:	06048513          	addi	a0,s1,96
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	564080e7          	jalr	1380(ra) # 8000266c <swtch>
    80002110:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002112:	2781                	sext.w	a5,a5
    80002114:	079e                	slli	a5,a5,0x7
    80002116:	97ca                	add	a5,a5,s2
    80002118:	0937aa23          	sw	s3,148(a5)
}
    8000211c:	70a2                	ld	ra,40(sp)
    8000211e:	7402                	ld	s0,32(sp)
    80002120:	64e2                	ld	s1,24(sp)
    80002122:	6942                	ld	s2,16(sp)
    80002124:	69a2                	ld	s3,8(sp)
    80002126:	6145                	addi	sp,sp,48
    80002128:	8082                	ret
    panic("sched p->lock");
    8000212a:	00006517          	auipc	a0,0x6
    8000212e:	0ee50513          	addi	a0,a0,238 # 80008218 <digits+0x1c0>
    80002132:	ffffe097          	auipc	ra,0xffffe
    80002136:	416080e7          	jalr	1046(ra) # 80000548 <panic>
    panic("sched locks");
    8000213a:	00006517          	auipc	a0,0x6
    8000213e:	0ee50513          	addi	a0,a0,238 # 80008228 <digits+0x1d0>
    80002142:	ffffe097          	auipc	ra,0xffffe
    80002146:	406080e7          	jalr	1030(ra) # 80000548 <panic>
    panic("sched running");
    8000214a:	00006517          	auipc	a0,0x6
    8000214e:	0ee50513          	addi	a0,a0,238 # 80008238 <digits+0x1e0>
    80002152:	ffffe097          	auipc	ra,0xffffe
    80002156:	3f6080e7          	jalr	1014(ra) # 80000548 <panic>
    panic("sched interruptible");
    8000215a:	00006517          	auipc	a0,0x6
    8000215e:	0ee50513          	addi	a0,a0,238 # 80008248 <digits+0x1f0>
    80002162:	ffffe097          	auipc	ra,0xffffe
    80002166:	3e6080e7          	jalr	998(ra) # 80000548 <panic>

000000008000216a <exit>:
{
    8000216a:	7179                	addi	sp,sp,-48
    8000216c:	f406                	sd	ra,40(sp)
    8000216e:	f022                	sd	s0,32(sp)
    80002170:	ec26                	sd	s1,24(sp)
    80002172:	e84a                	sd	s2,16(sp)
    80002174:	e44e                	sd	s3,8(sp)
    80002176:	e052                	sd	s4,0(sp)
    80002178:	1800                	addi	s0,sp,48
    8000217a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	8ce080e7          	jalr	-1842(ra) # 80001a4a <myproc>
    80002184:	89aa                	mv	s3,a0
  if(p == initproc)
    80002186:	00007797          	auipc	a5,0x7
    8000218a:	e927b783          	ld	a5,-366(a5) # 80009018 <initproc>
    8000218e:	0d050493          	addi	s1,a0,208
    80002192:	15050913          	addi	s2,a0,336
    80002196:	02a79363          	bne	a5,a0,800021bc <exit+0x52>
    panic("init exiting");
    8000219a:	00006517          	auipc	a0,0x6
    8000219e:	0c650513          	addi	a0,a0,198 # 80008260 <digits+0x208>
    800021a2:	ffffe097          	auipc	ra,0xffffe
    800021a6:	3a6080e7          	jalr	934(ra) # 80000548 <panic>
      fileclose(f);
    800021aa:	00002097          	auipc	ra,0x2
    800021ae:	49c080e7          	jalr	1180(ra) # 80004646 <fileclose>
      p->ofile[fd] = 0;
    800021b2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021b6:	04a1                	addi	s1,s1,8
    800021b8:	01248563          	beq	s1,s2,800021c2 <exit+0x58>
    if(p->ofile[fd]){
    800021bc:	6088                	ld	a0,0(s1)
    800021be:	f575                	bnez	a0,800021aa <exit+0x40>
    800021c0:	bfdd                	j	800021b6 <exit+0x4c>
  begin_op();
    800021c2:	00002097          	auipc	ra,0x2
    800021c6:	fb2080e7          	jalr	-78(ra) # 80004174 <begin_op>
  iput(p->cwd);
    800021ca:	1509b503          	ld	a0,336(s3)
    800021ce:	00001097          	auipc	ra,0x1
    800021d2:	7a4080e7          	jalr	1956(ra) # 80003972 <iput>
  end_op();
    800021d6:	00002097          	auipc	ra,0x2
    800021da:	01e080e7          	jalr	30(ra) # 800041f4 <end_op>
  p->cwd = 0;
    800021de:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021e2:	00007497          	auipc	s1,0x7
    800021e6:	e3648493          	addi	s1,s1,-458 # 80009018 <initproc>
    800021ea:	6088                	ld	a0,0(s1)
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	a90080e7          	jalr	-1392(ra) # 80000c7c <acquire>
  wakeup1(initproc);
    800021f4:	6088                	ld	a0,0(s1)
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	714080e7          	jalr	1812(ra) # 8000190a <wakeup1>
  release(&initproc->lock);
    800021fe:	6088                	ld	a0,0(s1)
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	b30080e7          	jalr	-1232(ra) # 80000d30 <release>
  acquire(&p->lock);
    80002208:	854e                	mv	a0,s3
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a72080e7          	jalr	-1422(ra) # 80000c7c <acquire>
  struct proc *original_parent = p->parent;
    80002212:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002216:	854e                	mv	a0,s3
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	b18080e7          	jalr	-1256(ra) # 80000d30 <release>
  acquire(&original_parent->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a5a080e7          	jalr	-1446(ra) # 80000c7c <acquire>
  acquire(&p->lock);
    8000222a:	854e                	mv	a0,s3
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	a50080e7          	jalr	-1456(ra) # 80000c7c <acquire>
  reparent(p);
    80002234:	854e                	mv	a0,s3
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	d38080e7          	jalr	-712(ra) # 80001f6e <reparent>
  wakeup1(original_parent);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	6ca080e7          	jalr	1738(ra) # 8000190a <wakeup1>
  p->xstate = status;
    80002248:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000224c:	4791                	li	a5,4
    8000224e:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	adc080e7          	jalr	-1316(ra) # 80000d30 <release>
  sched();
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	e38080e7          	jalr	-456(ra) # 80002094 <sched>
  panic("zombie exit");
    80002264:	00006517          	auipc	a0,0x6
    80002268:	00c50513          	addi	a0,a0,12 # 80008270 <digits+0x218>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	2dc080e7          	jalr	732(ra) # 80000548 <panic>

0000000080002274 <yield>:
{
    80002274:	1101                	addi	sp,sp,-32
    80002276:	ec06                	sd	ra,24(sp)
    80002278:	e822                	sd	s0,16(sp)
    8000227a:	e426                	sd	s1,8(sp)
    8000227c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	7cc080e7          	jalr	1996(ra) # 80001a4a <myproc>
    80002286:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	9f4080e7          	jalr	-1548(ra) # 80000c7c <acquire>
  p->state = RUNNABLE;
    80002290:	4789                	li	a5,2
    80002292:	cc9c                	sw	a5,24(s1)
  sched();
    80002294:	00000097          	auipc	ra,0x0
    80002298:	e00080e7          	jalr	-512(ra) # 80002094 <sched>
  release(&p->lock);
    8000229c:	8526                	mv	a0,s1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	a92080e7          	jalr	-1390(ra) # 80000d30 <release>
}
    800022a6:	60e2                	ld	ra,24(sp)
    800022a8:	6442                	ld	s0,16(sp)
    800022aa:	64a2                	ld	s1,8(sp)
    800022ac:	6105                	addi	sp,sp,32
    800022ae:	8082                	ret

00000000800022b0 <sleep>:
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	89aa                	mv	s3,a0
    800022c0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	788080e7          	jalr	1928(ra) # 80001a4a <myproc>
    800022ca:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022cc:	05250663          	beq	a0,s2,80002318 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	9ac080e7          	jalr	-1620(ra) # 80000c7c <acquire>
    release(lk);
    800022d8:	854a                	mv	a0,s2
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	a56080e7          	jalr	-1450(ra) # 80000d30 <release>
  p->chan = chan;
    800022e2:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022e6:	4785                	li	a5,1
    800022e8:	cc9c                	sw	a5,24(s1)
  sched();
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	daa080e7          	jalr	-598(ra) # 80002094 <sched>
  p->chan = 0;
    800022f2:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	a38080e7          	jalr	-1480(ra) # 80000d30 <release>
    acquire(lk);
    80002300:	854a                	mv	a0,s2
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	97a080e7          	jalr	-1670(ra) # 80000c7c <acquire>
}
    8000230a:	70a2                	ld	ra,40(sp)
    8000230c:	7402                	ld	s0,32(sp)
    8000230e:	64e2                	ld	s1,24(sp)
    80002310:	6942                	ld	s2,16(sp)
    80002312:	69a2                	ld	s3,8(sp)
    80002314:	6145                	addi	sp,sp,48
    80002316:	8082                	ret
  p->chan = chan;
    80002318:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000231c:	4785                	li	a5,1
    8000231e:	cd1c                	sw	a5,24(a0)
  sched();
    80002320:	00000097          	auipc	ra,0x0
    80002324:	d74080e7          	jalr	-652(ra) # 80002094 <sched>
  p->chan = 0;
    80002328:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000232c:	bff9                	j	8000230a <sleep+0x5a>

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	702080e7          	jalr	1794(ra) # 80001a4a <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002352:	8c2a                	mv	s8,a0
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	928080e7          	jalr	-1752(ra) # 80000c7c <acquire>
    havekids = 0;
    8000235c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000235e:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002360:	00016997          	auipc	s3,0x16
    80002364:	c0898993          	addi	s3,s3,-1016 # 80017f68 <tickslock>
        havekids = 1;
    80002368:	4a85                	li	s5,1
    havekids = 0;
    8000236a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000236c:	00010497          	auipc	s1,0x10
    80002370:	9fc48493          	addi	s1,s1,-1540 # 80011d68 <proc>
    80002374:	a08d                	j	800023d6 <wait+0xa8>
          pid = np->pid;
    80002376:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000237a:	000b0e63          	beqz	s6,80002396 <wait+0x68>
    8000237e:	4691                	li	a3,4
    80002380:	03448613          	addi	a2,s1,52
    80002384:	85da                	mv	a1,s6
    80002386:	05093503          	ld	a0,80(s2)
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	3b4080e7          	jalr	948(ra) # 8000173e <copyout>
    80002392:	02054263          	bltz	a0,800023b6 <wait+0x88>
          freeproc(np);
    80002396:	8526                	mv	a0,s1
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	864080e7          	jalr	-1948(ra) # 80001bfc <freeproc>
          release(&np->lock);
    800023a0:	8526                	mv	a0,s1
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	98e080e7          	jalr	-1650(ra) # 80000d30 <release>
          release(&p->lock);
    800023aa:	854a                	mv	a0,s2
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	984080e7          	jalr	-1660(ra) # 80000d30 <release>
          return pid;
    800023b4:	a8a9                	j	8000240e <wait+0xe0>
            release(&np->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	978080e7          	jalr	-1672(ra) # 80000d30 <release>
            release(&p->lock);
    800023c0:	854a                	mv	a0,s2
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	96e080e7          	jalr	-1682(ra) # 80000d30 <release>
            return -1;
    800023ca:	59fd                	li	s3,-1
    800023cc:	a089                	j	8000240e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023ce:	18848493          	addi	s1,s1,392
    800023d2:	03348463          	beq	s1,s3,800023fa <wait+0xcc>
      if(np->parent == p){
    800023d6:	709c                	ld	a5,32(s1)
    800023d8:	ff279be3          	bne	a5,s2,800023ce <wait+0xa0>
        acquire(&np->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	89e080e7          	jalr	-1890(ra) # 80000c7c <acquire>
        if(np->state == ZOMBIE){
    800023e6:	4c9c                	lw	a5,24(s1)
    800023e8:	f94787e3          	beq	a5,s4,80002376 <wait+0x48>
        release(&np->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	942080e7          	jalr	-1726(ra) # 80000d30 <release>
        havekids = 1;
    800023f6:	8756                	mv	a4,s5
    800023f8:	bfd9                	j	800023ce <wait+0xa0>
    if(!havekids || p->killed){
    800023fa:	c701                	beqz	a4,80002402 <wait+0xd4>
    800023fc:	03092783          	lw	a5,48(s2)
    80002400:	c785                	beqz	a5,80002428 <wait+0xfa>
      release(&p->lock);
    80002402:	854a                	mv	a0,s2
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	92c080e7          	jalr	-1748(ra) # 80000d30 <release>
      return -1;
    8000240c:	59fd                	li	s3,-1
}
    8000240e:	854e                	mv	a0,s3
    80002410:	60a6                	ld	ra,72(sp)
    80002412:	6406                	ld	s0,64(sp)
    80002414:	74e2                	ld	s1,56(sp)
    80002416:	7942                	ld	s2,48(sp)
    80002418:	79a2                	ld	s3,40(sp)
    8000241a:	7a02                	ld	s4,32(sp)
    8000241c:	6ae2                	ld	s5,24(sp)
    8000241e:	6b42                	ld	s6,16(sp)
    80002420:	6ba2                	ld	s7,8(sp)
    80002422:	6c02                	ld	s8,0(sp)
    80002424:	6161                	addi	sp,sp,80
    80002426:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002428:	85e2                	mv	a1,s8
    8000242a:	854a                	mv	a0,s2
    8000242c:	00000097          	auipc	ra,0x0
    80002430:	e84080e7          	jalr	-380(ra) # 800022b0 <sleep>
    havekids = 0;
    80002434:	bf1d                	j	8000236a <wait+0x3c>

0000000080002436 <wakeup>:
{
    80002436:	7139                	addi	sp,sp,-64
    80002438:	fc06                	sd	ra,56(sp)
    8000243a:	f822                	sd	s0,48(sp)
    8000243c:	f426                	sd	s1,40(sp)
    8000243e:	f04a                	sd	s2,32(sp)
    80002440:	ec4e                	sd	s3,24(sp)
    80002442:	e852                	sd	s4,16(sp)
    80002444:	e456                	sd	s5,8(sp)
    80002446:	0080                	addi	s0,sp,64
    80002448:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000244a:	00010497          	auipc	s1,0x10
    8000244e:	91e48493          	addi	s1,s1,-1762 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002452:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002454:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002456:	00016917          	auipc	s2,0x16
    8000245a:	b1290913          	addi	s2,s2,-1262 # 80017f68 <tickslock>
    8000245e:	a821                	j	80002476 <wakeup+0x40>
      p->state = RUNNABLE;
    80002460:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	8ca080e7          	jalr	-1846(ra) # 80000d30 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000246e:	18848493          	addi	s1,s1,392
    80002472:	01248e63          	beq	s1,s2,8000248e <wakeup+0x58>
    acquire(&p->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	804080e7          	jalr	-2044(ra) # 80000c7c <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	ff3791e3          	bne	a5,s3,80002464 <wakeup+0x2e>
    80002486:	749c                	ld	a5,40(s1)
    80002488:	fd479ee3          	bne	a5,s4,80002464 <wakeup+0x2e>
    8000248c:	bfd1                	j	80002460 <wakeup+0x2a>
}
    8000248e:	70e2                	ld	ra,56(sp)
    80002490:	7442                	ld	s0,48(sp)
    80002492:	74a2                	ld	s1,40(sp)
    80002494:	7902                	ld	s2,32(sp)
    80002496:	69e2                	ld	s3,24(sp)
    80002498:	6a42                	ld	s4,16(sp)
    8000249a:	6aa2                	ld	s5,8(sp)
    8000249c:	6121                	addi	sp,sp,64
    8000249e:	8082                	ret

00000000800024a0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024a0:	7179                	addi	sp,sp,-48
    800024a2:	f406                	sd	ra,40(sp)
    800024a4:	f022                	sd	s0,32(sp)
    800024a6:	ec26                	sd	s1,24(sp)
    800024a8:	e84a                	sd	s2,16(sp)
    800024aa:	e44e                	sd	s3,8(sp)
    800024ac:	1800                	addi	s0,sp,48
    800024ae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024b0:	00010497          	auipc	s1,0x10
    800024b4:	8b848493          	addi	s1,s1,-1864 # 80011d68 <proc>
    800024b8:	00016997          	auipc	s3,0x16
    800024bc:	ab098993          	addi	s3,s3,-1360 # 80017f68 <tickslock>
    acquire(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7ba080e7          	jalr	1978(ra) # 80000c7c <acquire>
    if(p->pid == pid){
    800024ca:	5c9c                	lw	a5,56(s1)
    800024cc:	01278d63          	beq	a5,s2,800024e6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	85e080e7          	jalr	-1954(ra) # 80000d30 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024da:	18848493          	addi	s1,s1,392
    800024de:	ff3491e3          	bne	s1,s3,800024c0 <kill+0x20>
  }
  return -1;
    800024e2:	557d                	li	a0,-1
    800024e4:	a829                	j	800024fe <kill+0x5e>
      p->killed = 1;
    800024e6:	4785                	li	a5,1
    800024e8:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024ea:	4c98                	lw	a4,24(s1)
    800024ec:	4785                	li	a5,1
    800024ee:	00f70f63          	beq	a4,a5,8000250c <kill+0x6c>
      release(&p->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	83c080e7          	jalr	-1988(ra) # 80000d30 <release>
      return 0;
    800024fc:	4501                	li	a0,0
}
    800024fe:	70a2                	ld	ra,40(sp)
    80002500:	7402                	ld	s0,32(sp)
    80002502:	64e2                	ld	s1,24(sp)
    80002504:	6942                	ld	s2,16(sp)
    80002506:	69a2                	ld	s3,8(sp)
    80002508:	6145                	addi	sp,sp,48
    8000250a:	8082                	ret
        p->state = RUNNABLE;
    8000250c:	4789                	li	a5,2
    8000250e:	cc9c                	sw	a5,24(s1)
    80002510:	b7cd                	j	800024f2 <kill+0x52>

0000000080002512 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002512:	7179                	addi	sp,sp,-48
    80002514:	f406                	sd	ra,40(sp)
    80002516:	f022                	sd	s0,32(sp)
    80002518:	ec26                	sd	s1,24(sp)
    8000251a:	e84a                	sd	s2,16(sp)
    8000251c:	e44e                	sd	s3,8(sp)
    8000251e:	e052                	sd	s4,0(sp)
    80002520:	1800                	addi	s0,sp,48
    80002522:	84aa                	mv	s1,a0
    80002524:	892e                	mv	s2,a1
    80002526:	89b2                	mv	s3,a2
    80002528:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	520080e7          	jalr	1312(ra) # 80001a4a <myproc>
  if(user_dst){
    80002532:	c08d                	beqz	s1,80002554 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002534:	86d2                	mv	a3,s4
    80002536:	864e                	mv	a2,s3
    80002538:	85ca                	mv	a1,s2
    8000253a:	6928                	ld	a0,80(a0)
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	202080e7          	jalr	514(ra) # 8000173e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002544:	70a2                	ld	ra,40(sp)
    80002546:	7402                	ld	s0,32(sp)
    80002548:	64e2                	ld	s1,24(sp)
    8000254a:	6942                	ld	s2,16(sp)
    8000254c:	69a2                	ld	s3,8(sp)
    8000254e:	6a02                	ld	s4,0(sp)
    80002550:	6145                	addi	sp,sp,48
    80002552:	8082                	ret
    memmove((char *)dst, src, len);
    80002554:	000a061b          	sext.w	a2,s4
    80002558:	85ce                	mv	a1,s3
    8000255a:	854a                	mv	a0,s2
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	87c080e7          	jalr	-1924(ra) # 80000dd8 <memmove>
    return 0;
    80002564:	8526                	mv	a0,s1
    80002566:	bff9                	j	80002544 <either_copyout+0x32>

0000000080002568 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002568:	7179                	addi	sp,sp,-48
    8000256a:	f406                	sd	ra,40(sp)
    8000256c:	f022                	sd	s0,32(sp)
    8000256e:	ec26                	sd	s1,24(sp)
    80002570:	e84a                	sd	s2,16(sp)
    80002572:	e44e                	sd	s3,8(sp)
    80002574:	e052                	sd	s4,0(sp)
    80002576:	1800                	addi	s0,sp,48
    80002578:	892a                	mv	s2,a0
    8000257a:	84ae                	mv	s1,a1
    8000257c:	89b2                	mv	s3,a2
    8000257e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	4ca080e7          	jalr	1226(ra) # 80001a4a <myproc>
  if(user_src){
    80002588:	c08d                	beqz	s1,800025aa <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000258a:	86d2                	mv	a3,s4
    8000258c:	864e                	mv	a2,s3
    8000258e:	85ca                	mv	a1,s2
    80002590:	6928                	ld	a0,80(a0)
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	238080e7          	jalr	568(ra) # 800017ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6a02                	ld	s4,0(sp)
    800025a6:	6145                	addi	sp,sp,48
    800025a8:	8082                	ret
    memmove(dst, (char*)src, len);
    800025aa:	000a061b          	sext.w	a2,s4
    800025ae:	85ce                	mv	a1,s3
    800025b0:	854a                	mv	a0,s2
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	826080e7          	jalr	-2010(ra) # 80000dd8 <memmove>
    return 0;
    800025ba:	8526                	mv	a0,s1
    800025bc:	bff9                	j	8000259a <either_copyin+0x32>

00000000800025be <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025be:	715d                	addi	sp,sp,-80
    800025c0:	e486                	sd	ra,72(sp)
    800025c2:	e0a2                	sd	s0,64(sp)
    800025c4:	fc26                	sd	s1,56(sp)
    800025c6:	f84a                	sd	s2,48(sp)
    800025c8:	f44e                	sd	s3,40(sp)
    800025ca:	f052                	sd	s4,32(sp)
    800025cc:	ec56                	sd	s5,24(sp)
    800025ce:	e85a                	sd	s6,16(sp)
    800025d0:	e45e                	sd	s7,8(sp)
    800025d2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025d4:	00006517          	auipc	a0,0x6
    800025d8:	b0c50513          	addi	a0,a0,-1268 # 800080e0 <digits+0x88>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	fb6080e7          	jalr	-74(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e4:	00010497          	auipc	s1,0x10
    800025e8:	8dc48493          	addi	s1,s1,-1828 # 80011ec0 <proc+0x158>
    800025ec:	00016917          	auipc	s2,0x16
    800025f0:	ad490913          	addi	s2,s2,-1324 # 800180c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f4:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025f6:	00006997          	auipc	s3,0x6
    800025fa:	c8a98993          	addi	s3,s3,-886 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025fe:	00006a97          	auipc	s5,0x6
    80002602:	c8aa8a93          	addi	s5,s5,-886 # 80008288 <digits+0x230>
    printf("\n");
    80002606:	00006a17          	auipc	s4,0x6
    8000260a:	adaa0a13          	addi	s4,s4,-1318 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000260e:	00006b97          	auipc	s7,0x6
    80002612:	cb2b8b93          	addi	s7,s7,-846 # 800082c0 <states.1713>
    80002616:	a00d                	j	80002638 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002618:	ee06a583          	lw	a1,-288(a3)
    8000261c:	8556                	mv	a0,s5
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	f74080e7          	jalr	-140(ra) # 80000592 <printf>
    printf("\n");
    80002626:	8552                	mv	a0,s4
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	f6a080e7          	jalr	-150(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002630:	18848493          	addi	s1,s1,392
    80002634:	03248163          	beq	s1,s2,80002656 <procdump+0x98>
    if(p->state == UNUSED)
    80002638:	86a6                	mv	a3,s1
    8000263a:	ec04a783          	lw	a5,-320(s1)
    8000263e:	dbed                	beqz	a5,80002630 <procdump+0x72>
      state = "???";
    80002640:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002642:	fcfb6be3          	bltu	s6,a5,80002618 <procdump+0x5a>
    80002646:	1782                	slli	a5,a5,0x20
    80002648:	9381                	srli	a5,a5,0x20
    8000264a:	078e                	slli	a5,a5,0x3
    8000264c:	97de                	add	a5,a5,s7
    8000264e:	6390                	ld	a2,0(a5)
    80002650:	f661                	bnez	a2,80002618 <procdump+0x5a>
      state = "???";
    80002652:	864e                	mv	a2,s3
    80002654:	b7d1                	j	80002618 <procdump+0x5a>
  }
}
    80002656:	60a6                	ld	ra,72(sp)
    80002658:	6406                	ld	s0,64(sp)
    8000265a:	74e2                	ld	s1,56(sp)
    8000265c:	7942                	ld	s2,48(sp)
    8000265e:	79a2                	ld	s3,40(sp)
    80002660:	7a02                	ld	s4,32(sp)
    80002662:	6ae2                	ld	s5,24(sp)
    80002664:	6b42                	ld	s6,16(sp)
    80002666:	6ba2                	ld	s7,8(sp)
    80002668:	6161                	addi	sp,sp,80
    8000266a:	8082                	ret

000000008000266c <swtch>:
    8000266c:	00153023          	sd	ra,0(a0)
    80002670:	00253423          	sd	sp,8(a0)
    80002674:	e900                	sd	s0,16(a0)
    80002676:	ed04                	sd	s1,24(a0)
    80002678:	03253023          	sd	s2,32(a0)
    8000267c:	03353423          	sd	s3,40(a0)
    80002680:	03453823          	sd	s4,48(a0)
    80002684:	03553c23          	sd	s5,56(a0)
    80002688:	05653023          	sd	s6,64(a0)
    8000268c:	05753423          	sd	s7,72(a0)
    80002690:	05853823          	sd	s8,80(a0)
    80002694:	05953c23          	sd	s9,88(a0)
    80002698:	07a53023          	sd	s10,96(a0)
    8000269c:	07b53423          	sd	s11,104(a0)
    800026a0:	0005b083          	ld	ra,0(a1)
    800026a4:	0085b103          	ld	sp,8(a1)
    800026a8:	6980                	ld	s0,16(a1)
    800026aa:	6d84                	ld	s1,24(a1)
    800026ac:	0205b903          	ld	s2,32(a1)
    800026b0:	0285b983          	ld	s3,40(a1)
    800026b4:	0305ba03          	ld	s4,48(a1)
    800026b8:	0385ba83          	ld	s5,56(a1)
    800026bc:	0405bb03          	ld	s6,64(a1)
    800026c0:	0485bb83          	ld	s7,72(a1)
    800026c4:	0505bc03          	ld	s8,80(a1)
    800026c8:	0585bc83          	ld	s9,88(a1)
    800026cc:	0605bd03          	ld	s10,96(a1)
    800026d0:	0685bd83          	ld	s11,104(a1)
    800026d4:	8082                	ret

00000000800026d6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d6:	1141                	addi	sp,sp,-16
    800026d8:	e406                	sd	ra,8(sp)
    800026da:	e022                	sd	s0,0(sp)
    800026dc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026de:	00006597          	auipc	a1,0x6
    800026e2:	c0a58593          	addi	a1,a1,-1014 # 800082e8 <states.1713+0x28>
    800026e6:	00016517          	auipc	a0,0x16
    800026ea:	88250513          	addi	a0,a0,-1918 # 80017f68 <tickslock>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	4fe080e7          	jalr	1278(ra) # 80000bec <initlock>
}
    800026f6:	60a2                	ld	ra,8(sp)
    800026f8:	6402                	ld	s0,0(sp)
    800026fa:	0141                	addi	sp,sp,16
    800026fc:	8082                	ret

00000000800026fe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026fe:	1141                	addi	sp,sp,-16
    80002700:	e422                	sd	s0,8(sp)
    80002702:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002704:	00003797          	auipc	a5,0x3
    80002708:	5ac78793          	addi	a5,a5,1452 # 80005cb0 <kernelvec>
    8000270c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002710:	6422                	ld	s0,8(sp)
    80002712:	0141                	addi	sp,sp,16
    80002714:	8082                	ret

0000000080002716 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002716:	1141                	addi	sp,sp,-16
    80002718:	e406                	sd	ra,8(sp)
    8000271a:	e022                	sd	s0,0(sp)
    8000271c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000271e:	fffff097          	auipc	ra,0xfffff
    80002722:	32c080e7          	jalr	812(ra) # 80001a4a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002726:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000272a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002730:	00005617          	auipc	a2,0x5
    80002734:	8d060613          	addi	a2,a2,-1840 # 80007000 <_trampoline>
    80002738:	00005697          	auipc	a3,0x5
    8000273c:	8c868693          	addi	a3,a3,-1848 # 80007000 <_trampoline>
    80002740:	8e91                	sub	a3,a3,a2
    80002742:	040007b7          	lui	a5,0x4000
    80002746:	17fd                	addi	a5,a5,-1
    80002748:	07b2                	slli	a5,a5,0xc
    8000274a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000274c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002750:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002752:	180026f3          	csrr	a3,satp
    80002756:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002758:	6d38                	ld	a4,88(a0)
    8000275a:	6134                	ld	a3,64(a0)
    8000275c:	6585                	lui	a1,0x1
    8000275e:	96ae                	add	a3,a3,a1
    80002760:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002762:	6d38                	ld	a4,88(a0)
    80002764:	00000697          	auipc	a3,0x0
    80002768:	13868693          	addi	a3,a3,312 # 8000289c <usertrap>
    8000276c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000276e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002770:	8692                	mv	a3,tp
    80002772:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002774:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002778:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000277c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002780:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002784:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002786:	6f18                	ld	a4,24(a4)
    80002788:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000278c:	692c                	ld	a1,80(a0)
    8000278e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002790:	00005717          	auipc	a4,0x5
    80002794:	90070713          	addi	a4,a4,-1792 # 80007090 <userret>
    80002798:	8f11                	sub	a4,a4,a2
    8000279a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000279c:	577d                	li	a4,-1
    8000279e:	177e                	slli	a4,a4,0x3f
    800027a0:	8dd9                	or	a1,a1,a4
    800027a2:	02000537          	lui	a0,0x2000
    800027a6:	157d                	addi	a0,a0,-1
    800027a8:	0536                	slli	a0,a0,0xd
    800027aa:	9782                	jalr	a5
}
    800027ac:	60a2                	ld	ra,8(sp)
    800027ae:	6402                	ld	s0,0(sp)
    800027b0:	0141                	addi	sp,sp,16
    800027b2:	8082                	ret

00000000800027b4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027b4:	1101                	addi	sp,sp,-32
    800027b6:	ec06                	sd	ra,24(sp)
    800027b8:	e822                	sd	s0,16(sp)
    800027ba:	e426                	sd	s1,8(sp)
    800027bc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027be:	00015497          	auipc	s1,0x15
    800027c2:	7aa48493          	addi	s1,s1,1962 # 80017f68 <tickslock>
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	4b4080e7          	jalr	1204(ra) # 80000c7c <acquire>
  ticks++;
    800027d0:	00007517          	auipc	a0,0x7
    800027d4:	85050513          	addi	a0,a0,-1968 # 80009020 <ticks>
    800027d8:	411c                	lw	a5,0(a0)
    800027da:	2785                	addiw	a5,a5,1
    800027dc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027de:	00000097          	auipc	ra,0x0
    800027e2:	c58080e7          	jalr	-936(ra) # 80002436 <wakeup>
  release(&tickslock);
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	548080e7          	jalr	1352(ra) # 80000d30 <release>
}
    800027f0:	60e2                	ld	ra,24(sp)
    800027f2:	6442                	ld	s0,16(sp)
    800027f4:	64a2                	ld	s1,8(sp)
    800027f6:	6105                	addi	sp,sp,32
    800027f8:	8082                	ret

00000000800027fa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027fa:	1101                	addi	sp,sp,-32
    800027fc:	ec06                	sd	ra,24(sp)
    800027fe:	e822                	sd	s0,16(sp)
    80002800:	e426                	sd	s1,8(sp)
    80002802:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002804:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002808:	00074d63          	bltz	a4,80002822 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000280c:	57fd                	li	a5,-1
    8000280e:	17fe                	slli	a5,a5,0x3f
    80002810:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002812:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002814:	06f70363          	beq	a4,a5,8000287a <devintr+0x80>
  }
}
    80002818:	60e2                	ld	ra,24(sp)
    8000281a:	6442                	ld	s0,16(sp)
    8000281c:	64a2                	ld	s1,8(sp)
    8000281e:	6105                	addi	sp,sp,32
    80002820:	8082                	ret
     (scause & 0xff) == 9){
    80002822:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002826:	46a5                	li	a3,9
    80002828:	fed792e3          	bne	a5,a3,8000280c <devintr+0x12>
    int irq = plic_claim();
    8000282c:	00003097          	auipc	ra,0x3
    80002830:	58c080e7          	jalr	1420(ra) # 80005db8 <plic_claim>
    80002834:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002836:	47a9                	li	a5,10
    80002838:	02f50763          	beq	a0,a5,80002866 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000283c:	4785                	li	a5,1
    8000283e:	02f50963          	beq	a0,a5,80002870 <devintr+0x76>
    return 1;
    80002842:	4505                	li	a0,1
    } else if(irq){
    80002844:	d8f1                	beqz	s1,80002818 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002846:	85a6                	mv	a1,s1
    80002848:	00006517          	auipc	a0,0x6
    8000284c:	aa850513          	addi	a0,a0,-1368 # 800082f0 <states.1713+0x30>
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	d42080e7          	jalr	-702(ra) # 80000592 <printf>
      plic_complete(irq);
    80002858:	8526                	mv	a0,s1
    8000285a:	00003097          	auipc	ra,0x3
    8000285e:	582080e7          	jalr	1410(ra) # 80005ddc <plic_complete>
    return 1;
    80002862:	4505                	li	a0,1
    80002864:	bf55                	j	80002818 <devintr+0x1e>
      uartintr();
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	1da080e7          	jalr	474(ra) # 80000a40 <uartintr>
    8000286e:	b7ed                	j	80002858 <devintr+0x5e>
      virtio_disk_intr();
    80002870:	00004097          	auipc	ra,0x4
    80002874:	a06080e7          	jalr	-1530(ra) # 80006276 <virtio_disk_intr>
    80002878:	b7c5                	j	80002858 <devintr+0x5e>
    if(cpuid() == 0){
    8000287a:	fffff097          	auipc	ra,0xfffff
    8000287e:	1a4080e7          	jalr	420(ra) # 80001a1e <cpuid>
    80002882:	c901                	beqz	a0,80002892 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002884:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002888:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000288a:	14479073          	csrw	sip,a5
    return 2;
    8000288e:	4509                	li	a0,2
    80002890:	b761                	j	80002818 <devintr+0x1e>
      clockintr();
    80002892:	00000097          	auipc	ra,0x0
    80002896:	f22080e7          	jalr	-222(ra) # 800027b4 <clockintr>
    8000289a:	b7ed                	j	80002884 <devintr+0x8a>

000000008000289c <usertrap>:
{
    8000289c:	1101                	addi	sp,sp,-32
    8000289e:	ec06                	sd	ra,24(sp)
    800028a0:	e822                	sd	s0,16(sp)
    800028a2:	e426                	sd	s1,8(sp)
    800028a4:	e04a                	sd	s2,0(sp)
    800028a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028ac:	1007f793          	andi	a5,a5,256
    800028b0:	e3ad                	bnez	a5,80002912 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b2:	00003797          	auipc	a5,0x3
    800028b6:	3fe78793          	addi	a5,a5,1022 # 80005cb0 <kernelvec>
    800028ba:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	18c080e7          	jalr	396(ra) # 80001a4a <myproc>
    800028c6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028c8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ca:	14102773          	csrr	a4,sepc
    800028ce:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028d4:	47a1                	li	a5,8
    800028d6:	04f71c63          	bne	a4,a5,8000292e <usertrap+0x92>
    if(p->killed)
    800028da:	591c                	lw	a5,48(a0)
    800028dc:	e3b9                	bnez	a5,80002922 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028de:	6cb8                	ld	a4,88(s1)
    800028e0:	6f1c                	ld	a5,24(a4)
    800028e2:	0791                	addi	a5,a5,4
    800028e4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ee:	10079073          	csrw	sstatus,a5
    syscall();
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	332080e7          	jalr	818(ra) # 80002c24 <syscall>
  if(p->killed)
    800028fa:	589c                	lw	a5,48(s1)
    800028fc:	efd5                	bnez	a5,800029b8 <usertrap+0x11c>
  usertrapret();
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	e18080e7          	jalr	-488(ra) # 80002716 <usertrapret>
}
    80002906:	60e2                	ld	ra,24(sp)
    80002908:	6442                	ld	s0,16(sp)
    8000290a:	64a2                	ld	s1,8(sp)
    8000290c:	6902                	ld	s2,0(sp)
    8000290e:	6105                	addi	sp,sp,32
    80002910:	8082                	ret
    panic("usertrap: not from user mode");
    80002912:	00006517          	auipc	a0,0x6
    80002916:	9fe50513          	addi	a0,a0,-1538 # 80008310 <states.1713+0x50>
    8000291a:	ffffe097          	auipc	ra,0xffffe
    8000291e:	c2e080e7          	jalr	-978(ra) # 80000548 <panic>
      exit(-1);
    80002922:	557d                	li	a0,-1
    80002924:	00000097          	auipc	ra,0x0
    80002928:	846080e7          	jalr	-1978(ra) # 8000216a <exit>
    8000292c:	bf4d                	j	800028de <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000292e:	00000097          	auipc	ra,0x0
    80002932:	ecc080e7          	jalr	-308(ra) # 800027fa <devintr>
    80002936:	892a                	mv	s2,a0
    80002938:	c501                	beqz	a0,80002940 <usertrap+0xa4>
  if(p->killed)
    8000293a:	589c                	lw	a5,48(s1)
    8000293c:	c3a1                	beqz	a5,8000297c <usertrap+0xe0>
    8000293e:	a815                	j	80002972 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002940:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002944:	5c90                	lw	a2,56(s1)
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	9ea50513          	addi	a0,a0,-1558 # 80008330 <states.1713+0x70>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	c44080e7          	jalr	-956(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002956:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000295a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000295e:	00006517          	auipc	a0,0x6
    80002962:	a0250513          	addi	a0,a0,-1534 # 80008360 <states.1713+0xa0>
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	c2c080e7          	jalr	-980(ra) # 80000592 <printf>
    p->killed = 1;
    8000296e:	4785                	li	a5,1
    80002970:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002972:	557d                	li	a0,-1
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	7f6080e7          	jalr	2038(ra) # 8000216a <exit>
  if(which_dev == 2) {
    8000297c:	4789                	li	a5,2
    8000297e:	f8f910e3          	bne	s2,a5,800028fe <usertrap+0x62>
      struct proc *p = myproc();
    80002982:	fffff097          	auipc	ra,0xfffff
    80002986:	0c8080e7          	jalr	200(ra) # 80001a4a <myproc>
    8000298a:	84aa                	mv	s1,a0
      if (p != 0 && p->alarm_interval > 0) {
    8000298c:	c10d                	beqz	a0,800029ae <usertrap+0x112>
    8000298e:	16852703          	lw	a4,360(a0)
    80002992:	00e05e63          	blez	a4,800029ae <usertrap+0x112>
        p->ticks_count++;
    80002996:	17852783          	lw	a5,376(a0)
    8000299a:	2785                	addiw	a5,a5,1
    8000299c:	0007869b          	sext.w	a3,a5
    800029a0:	16f52c23          	sw	a5,376(a0)
        if (p->ticks_count >= p->alarm_interval && p->is_alarming == 0) {
    800029a4:	00e6c563          	blt	a3,a4,800029ae <usertrap+0x112>
    800029a8:	17c52783          	lw	a5,380(a0)
    800029ac:	cb81                	beqz	a5,800029bc <usertrap+0x120>
      yield();
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	8c6080e7          	jalr	-1850(ra) # 80002274 <yield>
    800029b6:	b7a1                	j	800028fe <usertrap+0x62>
  int which_dev = 0;
    800029b8:	4901                	li	s2,0
    800029ba:	bf65                	j	80002972 <usertrap+0xd6>
          memmove(p->alarm_trapframe, p->trapframe, sizeof(struct trapframe));
    800029bc:	12000613          	li	a2,288
    800029c0:	6d2c                	ld	a1,88(a0)
    800029c2:	18053503          	ld	a0,384(a0)
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	412080e7          	jalr	1042(ra) # 80000dd8 <memmove>
          p->trapframe->epc = (uint64)p->alarm_handler;
    800029ce:	6cbc                	ld	a5,88(s1)
    800029d0:	1704b703          	ld	a4,368(s1)
    800029d4:	ef98                	sd	a4,24(a5)
          p->ticks_count = 0;
    800029d6:	1604ac23          	sw	zero,376(s1)
          p->is_alarming = 1;
    800029da:	4785                	li	a5,1
    800029dc:	16f4ae23          	sw	a5,380(s1)
    800029e0:	b7f9                	j	800029ae <usertrap+0x112>

00000000800029e2 <kerneltrap>:
{
    800029e2:	7179                	addi	sp,sp,-48
    800029e4:	f406                	sd	ra,40(sp)
    800029e6:	f022                	sd	s0,32(sp)
    800029e8:	ec26                	sd	s1,24(sp)
    800029ea:	e84a                	sd	s2,16(sp)
    800029ec:	e44e                	sd	s3,8(sp)
    800029ee:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029fc:	1004f793          	andi	a5,s1,256
    80002a00:	cb85                	beqz	a5,80002a30 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a06:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a08:	ef85                	bnez	a5,80002a40 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	df0080e7          	jalr	-528(ra) # 800027fa <devintr>
    80002a12:	cd1d                	beqz	a0,80002a50 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a14:	4789                	li	a5,2
    80002a16:	06f50a63          	beq	a0,a5,80002a8a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1e:	10049073          	csrw	sstatus,s1
}
    80002a22:	70a2                	ld	ra,40(sp)
    80002a24:	7402                	ld	s0,32(sp)
    80002a26:	64e2                	ld	s1,24(sp)
    80002a28:	6942                	ld	s2,16(sp)
    80002a2a:	69a2                	ld	s3,8(sp)
    80002a2c:	6145                	addi	sp,sp,48
    80002a2e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	95050513          	addi	a0,a0,-1712 # 80008380 <states.1713+0xc0>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b10080e7          	jalr	-1264(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	96850513          	addi	a0,a0,-1688 # 800083a8 <states.1713+0xe8>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	b00080e7          	jalr	-1280(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a50:	85ce                	mv	a1,s3
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	97650513          	addi	a0,a0,-1674 # 800083c8 <states.1713+0x108>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b38080e7          	jalr	-1224(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a66:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	96e50513          	addi	a0,a0,-1682 # 800083d8 <states.1713+0x118>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b20080e7          	jalr	-1248(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	97650513          	addi	a0,a0,-1674 # 800083f0 <states.1713+0x130>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	ac6080e7          	jalr	-1338(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	fc0080e7          	jalr	-64(ra) # 80001a4a <myproc>
    80002a92:	d541                	beqz	a0,80002a1a <kerneltrap+0x38>
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	fb6080e7          	jalr	-74(ra) # 80001a4a <myproc>
    80002a9c:	4d18                	lw	a4,24(a0)
    80002a9e:	478d                	li	a5,3
    80002aa0:	f6f71de3          	bne	a4,a5,80002a1a <kerneltrap+0x38>
    yield();
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	7d0080e7          	jalr	2000(ra) # 80002274 <yield>
    80002aac:	b7bd                	j	80002a1a <kerneltrap+0x38>

0000000080002aae <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	1000                	addi	s0,sp,32
    80002ab8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	f90080e7          	jalr	-112(ra) # 80001a4a <myproc>
  switch (n) {
    80002ac2:	4795                	li	a5,5
    80002ac4:	0497e163          	bltu	a5,s1,80002b06 <argraw+0x58>
    80002ac8:	048a                	slli	s1,s1,0x2
    80002aca:	00006717          	auipc	a4,0x6
    80002ace:	95e70713          	addi	a4,a4,-1698 # 80008428 <states.1713+0x168>
    80002ad2:	94ba                	add	s1,s1,a4
    80002ad4:	409c                	lw	a5,0(s1)
    80002ad6:	97ba                	add	a5,a5,a4
    80002ad8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ada:	6d3c                	ld	a5,88(a0)
    80002adc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret
    return p->trapframe->a1;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	7fa8                	ld	a0,120(a5)
    80002aec:	bfcd                	j	80002ade <argraw+0x30>
    return p->trapframe->a2;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	63c8                	ld	a0,128(a5)
    80002af2:	b7f5                	j	80002ade <argraw+0x30>
    return p->trapframe->a3;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	67c8                	ld	a0,136(a5)
    80002af8:	b7dd                	j	80002ade <argraw+0x30>
    return p->trapframe->a4;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	6bc8                	ld	a0,144(a5)
    80002afe:	b7c5                	j	80002ade <argraw+0x30>
    return p->trapframe->a5;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6fc8                	ld	a0,152(a5)
    80002b04:	bfe9                	j	80002ade <argraw+0x30>
  panic("argraw");
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	8fa50513          	addi	a0,a0,-1798 # 80008400 <states.1713+0x140>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a3a080e7          	jalr	-1478(ra) # 80000548 <panic>

0000000080002b16 <fetchaddr>:
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	e04a                	sd	s2,0(sp)
    80002b20:	1000                	addi	s0,sp,32
    80002b22:	84aa                	mv	s1,a0
    80002b24:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	f24080e7          	jalr	-220(ra) # 80001a4a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b2e:	653c                	ld	a5,72(a0)
    80002b30:	02f4f863          	bgeu	s1,a5,80002b60 <fetchaddr+0x4a>
    80002b34:	00848713          	addi	a4,s1,8
    80002b38:	02e7e663          	bltu	a5,a4,80002b64 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b3c:	46a1                	li	a3,8
    80002b3e:	8626                	mv	a2,s1
    80002b40:	85ca                	mv	a1,s2
    80002b42:	6928                	ld	a0,80(a0)
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	c86080e7          	jalr	-890(ra) # 800017ca <copyin>
    80002b4c:	00a03533          	snez	a0,a0
    80002b50:	40a00533          	neg	a0,a0
}
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6902                	ld	s2,0(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret
    return -1;
    80002b60:	557d                	li	a0,-1
    80002b62:	bfcd                	j	80002b54 <fetchaddr+0x3e>
    80002b64:	557d                	li	a0,-1
    80002b66:	b7fd                	j	80002b54 <fetchaddr+0x3e>

0000000080002b68 <fetchstr>:
{
    80002b68:	7179                	addi	sp,sp,-48
    80002b6a:	f406                	sd	ra,40(sp)
    80002b6c:	f022                	sd	s0,32(sp)
    80002b6e:	ec26                	sd	s1,24(sp)
    80002b70:	e84a                	sd	s2,16(sp)
    80002b72:	e44e                	sd	s3,8(sp)
    80002b74:	1800                	addi	s0,sp,48
    80002b76:	892a                	mv	s2,a0
    80002b78:	84ae                	mv	s1,a1
    80002b7a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	ece080e7          	jalr	-306(ra) # 80001a4a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b84:	86ce                	mv	a3,s3
    80002b86:	864a                	mv	a2,s2
    80002b88:	85a6                	mv	a1,s1
    80002b8a:	6928                	ld	a0,80(a0)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	cca080e7          	jalr	-822(ra) # 80001856 <copyinstr>
  if(err < 0)
    80002b94:	00054763          	bltz	a0,80002ba2 <fetchstr+0x3a>
  return strlen(buf);
    80002b98:	8526                	mv	a0,s1
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	366080e7          	jalr	870(ra) # 80000f00 <strlen>
}
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6145                	addi	sp,sp,48
    80002bae:	8082                	ret

0000000080002bb0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ef2080e7          	jalr	-270(ra) # 80002aae <argraw>
    80002bc4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bc6:	4501                	li	a0,0
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6105                	addi	sp,sp,32
    80002bd0:	8082                	ret

0000000080002bd2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd2:	1101                	addi	sp,sp,-32
    80002bd4:	ec06                	sd	ra,24(sp)
    80002bd6:	e822                	sd	s0,16(sp)
    80002bd8:	e426                	sd	s1,8(sp)
    80002bda:	1000                	addi	s0,sp,32
    80002bdc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	ed0080e7          	jalr	-304(ra) # 80002aae <argraw>
    80002be6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002be8:	4501                	li	a0,0
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	e04a                	sd	s2,0(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
    80002c02:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	eaa080e7          	jalr	-342(ra) # 80002aae <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c0c:	864a                	mv	a2,s2
    80002c0e:	85a6                	mv	a1,s1
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	f58080e7          	jalr	-168(ra) # 80002b68 <fetchstr>
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6902                	ld	s2,0(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	e04a                	sd	s2,0(sp)
    80002c2e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	e1a080e7          	jalr	-486(ra) # 80001a4a <myproc>
    80002c38:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3a:	05853903          	ld	s2,88(a0)
    80002c3e:	0a893783          	ld	a5,168(s2)
    80002c42:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c46:	37fd                	addiw	a5,a5,-1
    80002c48:	4759                	li	a4,22
    80002c4a:	00f76f63          	bltu	a4,a5,80002c68 <syscall+0x44>
    80002c4e:	00369713          	slli	a4,a3,0x3
    80002c52:	00005797          	auipc	a5,0x5
    80002c56:	7ee78793          	addi	a5,a5,2030 # 80008440 <syscalls>
    80002c5a:	97ba                	add	a5,a5,a4
    80002c5c:	639c                	ld	a5,0(a5)
    80002c5e:	c789                	beqz	a5,80002c68 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c60:	9782                	jalr	a5
    80002c62:	06a93823          	sd	a0,112(s2)
    80002c66:	a839                	j	80002c84 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c68:	15848613          	addi	a2,s1,344
    80002c6c:	5c8c                	lw	a1,56(s1)
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	79a50513          	addi	a0,a0,1946 # 80008408 <states.1713+0x148>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	91c080e7          	jalr	-1764(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c7e:	6cbc                	ld	a5,88(s1)
    80002c80:	577d                	li	a4,-1
    80002c82:	fbb8                	sd	a4,112(a5)
  }
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6902                	ld	s2,0(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c98:	fec40593          	addi	a1,s0,-20
    80002c9c:	4501                	li	a0,0
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	f12080e7          	jalr	-238(ra) # 80002bb0 <argint>
    return -1;
    80002ca6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca8:	00054963          	bltz	a0,80002cba <sys_exit+0x2a>
  exit(n);
    80002cac:	fec42503          	lw	a0,-20(s0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	4ba080e7          	jalr	1210(ra) # 8000216a <exit>
  return 0;  // not reached
    80002cb8:	4781                	li	a5,0
}
    80002cba:	853e                	mv	a0,a5
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e406                	sd	ra,8(sp)
    80002cc8:	e022                	sd	s0,0(sp)
    80002cca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	d7e080e7          	jalr	-642(ra) # 80001a4a <myproc>
}
    80002cd4:	5d08                	lw	a0,56(a0)
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_fork>:

uint64
sys_fork(void)
{
    80002cde:	1141                	addi	sp,sp,-16
    80002ce0:	e406                	sd	ra,8(sp)
    80002ce2:	e022                	sd	s0,0(sp)
    80002ce4:	0800                	addi	s0,sp,16
  return fork();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	17e080e7          	jalr	382(ra) # 80001e64 <fork>
}
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cfe:	fe840593          	addi	a1,s0,-24
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	ece080e7          	jalr	-306(ra) # 80002bd2 <argaddr>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d10:	0007c863          	bltz	a5,80002d20 <sys_wait+0x2a>
  return wait(p);
    80002d14:	fe843503          	ld	a0,-24(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	616080e7          	jalr	1558(ra) # 8000232e <wait>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d32:	fdc40593          	addi	a1,s0,-36
    80002d36:	4501                	li	a0,0
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	e78080e7          	jalr	-392(ra) # 80002bb0 <argint>
    80002d40:	87aa                	mv	a5,a0
    return -1;
    80002d42:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d44:	0207c063          	bltz	a5,80002d64 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	d02080e7          	jalr	-766(ra) # 80001a4a <myproc>
    80002d50:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d52:	fdc42503          	lw	a0,-36(s0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	09a080e7          	jalr	154(ra) # 80001df0 <growproc>
    80002d5e:	00054863          	bltz	a0,80002d6e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d62:	8526                	mv	a0,s1
}
    80002d64:	70a2                	ld	ra,40(sp)
    80002d66:	7402                	ld	s0,32(sp)
    80002d68:	64e2                	ld	s1,24(sp)
    80002d6a:	6145                	addi	sp,sp,48
    80002d6c:	8082                	ret
    return -1;
    80002d6e:	557d                	li	a0,-1
    80002d70:	bfd5                	j	80002d64 <sys_sbrk+0x3c>

0000000080002d72 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d72:	7139                	addi	sp,sp,-64
    80002d74:	fc06                	sd	ra,56(sp)
    80002d76:	f822                	sd	s0,48(sp)
    80002d78:	f426                	sd	s1,40(sp)
    80002d7a:	f04a                	sd	s2,32(sp)
    80002d7c:	ec4e                	sd	s3,24(sp)
    80002d7e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d80:	fcc40593          	addi	a1,s0,-52
    80002d84:	4501                	li	a0,0
    80002d86:	00000097          	auipc	ra,0x0
    80002d8a:	e2a080e7          	jalr	-470(ra) # 80002bb0 <argint>
    return -1;
    80002d8e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d90:	06054963          	bltz	a0,80002e02 <sys_sleep+0x90>

  // 在睡前打印回溯（用于测试）
  backtrace();
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	9e4080e7          	jalr	-1564(ra) # 80000778 <backtrace>
  
  acquire(&tickslock);
    80002d9c:	00015517          	auipc	a0,0x15
    80002da0:	1cc50513          	addi	a0,a0,460 # 80017f68 <tickslock>
    80002da4:	ffffe097          	auipc	ra,0xffffe
    80002da8:	ed8080e7          	jalr	-296(ra) # 80000c7c <acquire>
  ticks0 = ticks;
    80002dac:	00006917          	auipc	s2,0x6
    80002db0:	27492903          	lw	s2,628(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002db4:	fcc42783          	lw	a5,-52(s0)
    80002db8:	cf85                	beqz	a5,80002df0 <sys_sleep+0x7e>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dba:	00015997          	auipc	s3,0x15
    80002dbe:	1ae98993          	addi	s3,s3,430 # 80017f68 <tickslock>
    80002dc2:	00006497          	auipc	s1,0x6
    80002dc6:	25e48493          	addi	s1,s1,606 # 80009020 <ticks>
    if(myproc()->killed){
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	c80080e7          	jalr	-896(ra) # 80001a4a <myproc>
    80002dd2:	591c                	lw	a5,48(a0)
    80002dd4:	ef9d                	bnez	a5,80002e12 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002dd6:	85ce                	mv	a1,s3
    80002dd8:	8526                	mv	a0,s1
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	4d6080e7          	jalr	1238(ra) # 800022b0 <sleep>
  while(ticks - ticks0 < n){
    80002de2:	409c                	lw	a5,0(s1)
    80002de4:	412787bb          	subw	a5,a5,s2
    80002de8:	fcc42703          	lw	a4,-52(s0)
    80002dec:	fce7efe3          	bltu	a5,a4,80002dca <sys_sleep+0x58>
  }
  release(&tickslock);
    80002df0:	00015517          	auipc	a0,0x15
    80002df4:	17850513          	addi	a0,a0,376 # 80017f68 <tickslock>
    80002df8:	ffffe097          	auipc	ra,0xffffe
    80002dfc:	f38080e7          	jalr	-200(ra) # 80000d30 <release>
  return 0;
    80002e00:	4781                	li	a5,0
}
    80002e02:	853e                	mv	a0,a5
    80002e04:	70e2                	ld	ra,56(sp)
    80002e06:	7442                	ld	s0,48(sp)
    80002e08:	74a2                	ld	s1,40(sp)
    80002e0a:	7902                	ld	s2,32(sp)
    80002e0c:	69e2                	ld	s3,24(sp)
    80002e0e:	6121                	addi	sp,sp,64
    80002e10:	8082                	ret
      release(&tickslock);
    80002e12:	00015517          	auipc	a0,0x15
    80002e16:	15650513          	addi	a0,a0,342 # 80017f68 <tickslock>
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	f16080e7          	jalr	-234(ra) # 80000d30 <release>
      return -1;
    80002e22:	57fd                	li	a5,-1
    80002e24:	bff9                	j	80002e02 <sys_sleep+0x90>

0000000080002e26 <sys_kill>:

uint64
sys_kill(void)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e2e:	fec40593          	addi	a1,s0,-20
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	d7c080e7          	jalr	-644(ra) # 80002bb0 <argint>
    80002e3c:	87aa                	mv	a5,a0
    return -1;
    80002e3e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e40:	0007c863          	bltz	a5,80002e50 <sys_kill+0x2a>
  return kill(pid);
    80002e44:	fec42503          	lw	a0,-20(s0)
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	658080e7          	jalr	1624(ra) # 800024a0 <kill>
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	e426                	sd	s1,8(sp)
    80002e60:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e62:	00015517          	auipc	a0,0x15
    80002e66:	10650513          	addi	a0,a0,262 # 80017f68 <tickslock>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	e12080e7          	jalr	-494(ra) # 80000c7c <acquire>
  xticks = ticks;
    80002e72:	00006497          	auipc	s1,0x6
    80002e76:	1ae4a483          	lw	s1,430(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e7a:	00015517          	auipc	a0,0x15
    80002e7e:	0ee50513          	addi	a0,a0,238 # 80017f68 <tickslock>
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	eae080e7          	jalr	-338(ra) # 80000d30 <release>
  return xticks;
}
    80002e8a:	02049513          	slli	a0,s1,0x20
    80002e8e:	9101                	srli	a0,a0,0x20
    80002e90:	60e2                	ld	ra,24(sp)
    80002e92:	6442                	ld	s0,16(sp)
    80002e94:	64a2                	ld	s1,8(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret

0000000080002e9a <sys_sigalarm>:

// 

uint64
sys_sigalarm(void)
{
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	1000                	addi	s0,sp,32
  int interval;
  uint64 handler;   // address

  if (argint(0, &interval) < 0)
    80002ea2:	fec40593          	addi	a1,s0,-20
    80002ea6:	4501                	li	a0,0
    80002ea8:	00000097          	auipc	ra,0x0
    80002eac:	d08080e7          	jalr	-760(ra) # 80002bb0 <argint>
    return -1;
    80002eb0:	57fd                	li	a5,-1
  if (argint(0, &interval) < 0)
    80002eb2:	02054b63          	bltz	a0,80002ee8 <sys_sigalarm+0x4e>
  if (argaddr(1, &handler) < 0)
    80002eb6:	fe040593          	addi	a1,s0,-32
    80002eba:	4505                	li	a0,1
    80002ebc:	00000097          	auipc	ra,0x0
    80002ec0:	d16080e7          	jalr	-746(ra) # 80002bd2 <argaddr>
    return -1;
    80002ec4:	57fd                	li	a5,-1
  if (argaddr(1, &handler) < 0)
    80002ec6:	02054163          	bltz	a0,80002ee8 <sys_sigalarm+0x4e>

  struct proc *p = myproc();
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	b80080e7          	jalr	-1152(ra) # 80001a4a <myproc>

  p->alarm_interval = interval;
    80002ed2:	fec42783          	lw	a5,-20(s0)
    80002ed6:	16f52423          	sw	a5,360(a0)
  p->alarm_handler = (void(*)())handler;
    80002eda:	fe043783          	ld	a5,-32(s0)
    80002ede:	16f53823          	sd	a5,368(a0)
  p->ticks_count = 0;
    80002ee2:	16052c23          	sw	zero,376(a0)
  // is_alarming already initialized in allocproc
  return 0;
    80002ee6:	4781                	li	a5,0
}
    80002ee8:	853e                	mv	a0,a5
    80002eea:	60e2                	ld	ra,24(sp)
    80002eec:	6442                	ld	s0,16(sp)
    80002eee:	6105                	addi	sp,sp,32
    80002ef0:	8082                	ret

0000000080002ef2 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80002ef2:	1101                	addi	sp,sp,-32
    80002ef4:	ec06                	sd	ra,24(sp)
    80002ef6:	e822                	sd	s0,16(sp)
    80002ef8:	e426                	sd	s1,8(sp)
    80002efa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	b4e080e7          	jalr	-1202(ra) # 80001a4a <myproc>
    80002f04:	84aa                	mv	s1,a0
  // 恢复保存的 trapframe（恢复寄存器、epc 等）
  memmove(p->trapframe, p->alarm_trapframe, sizeof(struct trapframe));
    80002f06:	12000613          	li	a2,288
    80002f0a:	18053583          	ld	a1,384(a0)
    80002f0e:	6d28                	ld	a0,88(a0)
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	ec8080e7          	jalr	-312(ra) # 80000dd8 <memmove>
  p->is_alarming = 0;
    80002f18:	1604ae23          	sw	zero,380(s1)
  return 0;
}
    80002f1c:	4501                	li	a0,0
    80002f1e:	60e2                	ld	ra,24(sp)
    80002f20:	6442                	ld	s0,16(sp)
    80002f22:	64a2                	ld	s1,8(sp)
    80002f24:	6105                	addi	sp,sp,32
    80002f26:	8082                	ret

0000000080002f28 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f28:	7179                	addi	sp,sp,-48
    80002f2a:	f406                	sd	ra,40(sp)
    80002f2c:	f022                	sd	s0,32(sp)
    80002f2e:	ec26                	sd	s1,24(sp)
    80002f30:	e84a                	sd	s2,16(sp)
    80002f32:	e44e                	sd	s3,8(sp)
    80002f34:	e052                	sd	s4,0(sp)
    80002f36:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f38:	00005597          	auipc	a1,0x5
    80002f3c:	5c858593          	addi	a1,a1,1480 # 80008500 <syscalls+0xc0>
    80002f40:	00015517          	auipc	a0,0x15
    80002f44:	04050513          	addi	a0,a0,64 # 80017f80 <bcache>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	ca4080e7          	jalr	-860(ra) # 80000bec <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f50:	0001d797          	auipc	a5,0x1d
    80002f54:	03078793          	addi	a5,a5,48 # 8001ff80 <bcache+0x8000>
    80002f58:	0001d717          	auipc	a4,0x1d
    80002f5c:	29070713          	addi	a4,a4,656 # 800201e8 <bcache+0x8268>
    80002f60:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f64:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f68:	00015497          	auipc	s1,0x15
    80002f6c:	03048493          	addi	s1,s1,48 # 80017f98 <bcache+0x18>
    b->next = bcache.head.next;
    80002f70:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f72:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f74:	00005a17          	auipc	s4,0x5
    80002f78:	594a0a13          	addi	s4,s4,1428 # 80008508 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f7c:	2b893783          	ld	a5,696(s2)
    80002f80:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f82:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f86:	85d2                	mv	a1,s4
    80002f88:	01048513          	addi	a0,s1,16
    80002f8c:	00001097          	auipc	ra,0x1
    80002f90:	4ac080e7          	jalr	1196(ra) # 80004438 <initsleeplock>
    bcache.head.next->prev = b;
    80002f94:	2b893783          	ld	a5,696(s2)
    80002f98:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f9a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9e:	45848493          	addi	s1,s1,1112
    80002fa2:	fd349de3          	bne	s1,s3,80002f7c <binit+0x54>
  }
}
    80002fa6:	70a2                	ld	ra,40(sp)
    80002fa8:	7402                	ld	s0,32(sp)
    80002faa:	64e2                	ld	s1,24(sp)
    80002fac:	6942                	ld	s2,16(sp)
    80002fae:	69a2                	ld	s3,8(sp)
    80002fb0:	6a02                	ld	s4,0(sp)
    80002fb2:	6145                	addi	sp,sp,48
    80002fb4:	8082                	ret

0000000080002fb6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fb6:	7179                	addi	sp,sp,-48
    80002fb8:	f406                	sd	ra,40(sp)
    80002fba:	f022                	sd	s0,32(sp)
    80002fbc:	ec26                	sd	s1,24(sp)
    80002fbe:	e84a                	sd	s2,16(sp)
    80002fc0:	e44e                	sd	s3,8(sp)
    80002fc2:	1800                	addi	s0,sp,48
    80002fc4:	89aa                	mv	s3,a0
    80002fc6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fc8:	00015517          	auipc	a0,0x15
    80002fcc:	fb850513          	addi	a0,a0,-72 # 80017f80 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	cac080e7          	jalr	-852(ra) # 80000c7c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd8:	0001d497          	auipc	s1,0x1d
    80002fdc:	2604b483          	ld	s1,608(s1) # 80020238 <bcache+0x82b8>
    80002fe0:	0001d797          	auipc	a5,0x1d
    80002fe4:	20878793          	addi	a5,a5,520 # 800201e8 <bcache+0x8268>
    80002fe8:	02f48f63          	beq	s1,a5,80003026 <bread+0x70>
    80002fec:	873e                	mv	a4,a5
    80002fee:	a021                	j	80002ff6 <bread+0x40>
    80002ff0:	68a4                	ld	s1,80(s1)
    80002ff2:	02e48a63          	beq	s1,a4,80003026 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ff6:	449c                	lw	a5,8(s1)
    80002ff8:	ff379ce3          	bne	a5,s3,80002ff0 <bread+0x3a>
    80002ffc:	44dc                	lw	a5,12(s1)
    80002ffe:	ff2799e3          	bne	a5,s2,80002ff0 <bread+0x3a>
      b->refcnt++;
    80003002:	40bc                	lw	a5,64(s1)
    80003004:	2785                	addiw	a5,a5,1
    80003006:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003008:	00015517          	auipc	a0,0x15
    8000300c:	f7850513          	addi	a0,a0,-136 # 80017f80 <bcache>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	d20080e7          	jalr	-736(ra) # 80000d30 <release>
      acquiresleep(&b->lock);
    80003018:	01048513          	addi	a0,s1,16
    8000301c:	00001097          	auipc	ra,0x1
    80003020:	456080e7          	jalr	1110(ra) # 80004472 <acquiresleep>
      return b;
    80003024:	a8b9                	j	80003082 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003026:	0001d497          	auipc	s1,0x1d
    8000302a:	20a4b483          	ld	s1,522(s1) # 80020230 <bcache+0x82b0>
    8000302e:	0001d797          	auipc	a5,0x1d
    80003032:	1ba78793          	addi	a5,a5,442 # 800201e8 <bcache+0x8268>
    80003036:	00f48863          	beq	s1,a5,80003046 <bread+0x90>
    8000303a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000303c:	40bc                	lw	a5,64(s1)
    8000303e:	cf81                	beqz	a5,80003056 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003040:	64a4                	ld	s1,72(s1)
    80003042:	fee49de3          	bne	s1,a4,8000303c <bread+0x86>
  panic("bget: no buffers");
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	4ca50513          	addi	a0,a0,1226 # 80008510 <syscalls+0xd0>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	4fa080e7          	jalr	1274(ra) # 80000548 <panic>
      b->dev = dev;
    80003056:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000305a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000305e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003062:	4785                	li	a5,1
    80003064:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003066:	00015517          	auipc	a0,0x15
    8000306a:	f1a50513          	addi	a0,a0,-230 # 80017f80 <bcache>
    8000306e:	ffffe097          	auipc	ra,0xffffe
    80003072:	cc2080e7          	jalr	-830(ra) # 80000d30 <release>
      acquiresleep(&b->lock);
    80003076:	01048513          	addi	a0,s1,16
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	3f8080e7          	jalr	1016(ra) # 80004472 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003082:	409c                	lw	a5,0(s1)
    80003084:	cb89                	beqz	a5,80003096 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003086:	8526                	mv	a0,s1
    80003088:	70a2                	ld	ra,40(sp)
    8000308a:	7402                	ld	s0,32(sp)
    8000308c:	64e2                	ld	s1,24(sp)
    8000308e:	6942                	ld	s2,16(sp)
    80003090:	69a2                	ld	s3,8(sp)
    80003092:	6145                	addi	sp,sp,48
    80003094:	8082                	ret
    virtio_disk_rw(b, 0);
    80003096:	4581                	li	a1,0
    80003098:	8526                	mv	a0,s1
    8000309a:	00003097          	auipc	ra,0x3
    8000309e:	f32080e7          	jalr	-206(ra) # 80005fcc <virtio_disk_rw>
    b->valid = 1;
    800030a2:	4785                	li	a5,1
    800030a4:	c09c                	sw	a5,0(s1)
  return b;
    800030a6:	b7c5                	j	80003086 <bread+0xd0>

00000000800030a8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	1000                	addi	s0,sp,32
    800030b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b4:	0541                	addi	a0,a0,16
    800030b6:	00001097          	auipc	ra,0x1
    800030ba:	456080e7          	jalr	1110(ra) # 8000450c <holdingsleep>
    800030be:	cd01                	beqz	a0,800030d6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030c0:	4585                	li	a1,1
    800030c2:	8526                	mv	a0,s1
    800030c4:	00003097          	auipc	ra,0x3
    800030c8:	f08080e7          	jalr	-248(ra) # 80005fcc <virtio_disk_rw>
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	64a2                	ld	s1,8(sp)
    800030d2:	6105                	addi	sp,sp,32
    800030d4:	8082                	ret
    panic("bwrite");
    800030d6:	00005517          	auipc	a0,0x5
    800030da:	45250513          	addi	a0,a0,1106 # 80008528 <syscalls+0xe8>
    800030de:	ffffd097          	auipc	ra,0xffffd
    800030e2:	46a080e7          	jalr	1130(ra) # 80000548 <panic>

00000000800030e6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030e6:	1101                	addi	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	e426                	sd	s1,8(sp)
    800030ee:	e04a                	sd	s2,0(sp)
    800030f0:	1000                	addi	s0,sp,32
    800030f2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f4:	01050913          	addi	s2,a0,16
    800030f8:	854a                	mv	a0,s2
    800030fa:	00001097          	auipc	ra,0x1
    800030fe:	412080e7          	jalr	1042(ra) # 8000450c <holdingsleep>
    80003102:	c92d                	beqz	a0,80003174 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003104:	854a                	mv	a0,s2
    80003106:	00001097          	auipc	ra,0x1
    8000310a:	3c2080e7          	jalr	962(ra) # 800044c8 <releasesleep>

  acquire(&bcache.lock);
    8000310e:	00015517          	auipc	a0,0x15
    80003112:	e7250513          	addi	a0,a0,-398 # 80017f80 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b66080e7          	jalr	-1178(ra) # 80000c7c <acquire>
  b->refcnt--;
    8000311e:	40bc                	lw	a5,64(s1)
    80003120:	37fd                	addiw	a5,a5,-1
    80003122:	0007871b          	sext.w	a4,a5
    80003126:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003128:	eb05                	bnez	a4,80003158 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000312a:	68bc                	ld	a5,80(s1)
    8000312c:	64b8                	ld	a4,72(s1)
    8000312e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003130:	64bc                	ld	a5,72(s1)
    80003132:	68b8                	ld	a4,80(s1)
    80003134:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003136:	0001d797          	auipc	a5,0x1d
    8000313a:	e4a78793          	addi	a5,a5,-438 # 8001ff80 <bcache+0x8000>
    8000313e:	2b87b703          	ld	a4,696(a5)
    80003142:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003144:	0001d717          	auipc	a4,0x1d
    80003148:	0a470713          	addi	a4,a4,164 # 800201e8 <bcache+0x8268>
    8000314c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000314e:	2b87b703          	ld	a4,696(a5)
    80003152:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003154:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003158:	00015517          	auipc	a0,0x15
    8000315c:	e2850513          	addi	a0,a0,-472 # 80017f80 <bcache>
    80003160:	ffffe097          	auipc	ra,0xffffe
    80003164:	bd0080e7          	jalr	-1072(ra) # 80000d30 <release>
}
    80003168:	60e2                	ld	ra,24(sp)
    8000316a:	6442                	ld	s0,16(sp)
    8000316c:	64a2                	ld	s1,8(sp)
    8000316e:	6902                	ld	s2,0(sp)
    80003170:	6105                	addi	sp,sp,32
    80003172:	8082                	ret
    panic("brelse");
    80003174:	00005517          	auipc	a0,0x5
    80003178:	3bc50513          	addi	a0,a0,956 # 80008530 <syscalls+0xf0>
    8000317c:	ffffd097          	auipc	ra,0xffffd
    80003180:	3cc080e7          	jalr	972(ra) # 80000548 <panic>

0000000080003184 <bpin>:

void
bpin(struct buf *b) {
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003190:	00015517          	auipc	a0,0x15
    80003194:	df050513          	addi	a0,a0,-528 # 80017f80 <bcache>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	ae4080e7          	jalr	-1308(ra) # 80000c7c <acquire>
  b->refcnt++;
    800031a0:	40bc                	lw	a5,64(s1)
    800031a2:	2785                	addiw	a5,a5,1
    800031a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a6:	00015517          	auipc	a0,0x15
    800031aa:	dda50513          	addi	a0,a0,-550 # 80017f80 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	b82080e7          	jalr	-1150(ra) # 80000d30 <release>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret

00000000800031c0 <bunpin>:

void
bunpin(struct buf *b) {
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031cc:	00015517          	auipc	a0,0x15
    800031d0:	db450513          	addi	a0,a0,-588 # 80017f80 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	aa8080e7          	jalr	-1368(ra) # 80000c7c <acquire>
  b->refcnt--;
    800031dc:	40bc                	lw	a5,64(s1)
    800031de:	37fd                	addiw	a5,a5,-1
    800031e0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e2:	00015517          	auipc	a0,0x15
    800031e6:	d9e50513          	addi	a0,a0,-610 # 80017f80 <bcache>
    800031ea:	ffffe097          	auipc	ra,0xffffe
    800031ee:	b46080e7          	jalr	-1210(ra) # 80000d30 <release>
}
    800031f2:	60e2                	ld	ra,24(sp)
    800031f4:	6442                	ld	s0,16(sp)
    800031f6:	64a2                	ld	s1,8(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret

00000000800031fc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031fc:	1101                	addi	sp,sp,-32
    800031fe:	ec06                	sd	ra,24(sp)
    80003200:	e822                	sd	s0,16(sp)
    80003202:	e426                	sd	s1,8(sp)
    80003204:	e04a                	sd	s2,0(sp)
    80003206:	1000                	addi	s0,sp,32
    80003208:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000320a:	00d5d59b          	srliw	a1,a1,0xd
    8000320e:	0001d797          	auipc	a5,0x1d
    80003212:	44e7a783          	lw	a5,1102(a5) # 8002065c <sb+0x1c>
    80003216:	9dbd                	addw	a1,a1,a5
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	d9e080e7          	jalr	-610(ra) # 80002fb6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003220:	0074f713          	andi	a4,s1,7
    80003224:	4785                	li	a5,1
    80003226:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000322a:	14ce                	slli	s1,s1,0x33
    8000322c:	90d9                	srli	s1,s1,0x36
    8000322e:	00950733          	add	a4,a0,s1
    80003232:	05874703          	lbu	a4,88(a4)
    80003236:	00e7f6b3          	and	a3,a5,a4
    8000323a:	c69d                	beqz	a3,80003268 <bfree+0x6c>
    8000323c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000323e:	94aa                	add	s1,s1,a0
    80003240:	fff7c793          	not	a5,a5
    80003244:	8ff9                	and	a5,a5,a4
    80003246:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000324a:	00001097          	auipc	ra,0x1
    8000324e:	100080e7          	jalr	256(ra) # 8000434a <log_write>
  brelse(bp);
    80003252:	854a                	mv	a0,s2
    80003254:	00000097          	auipc	ra,0x0
    80003258:	e92080e7          	jalr	-366(ra) # 800030e6 <brelse>
}
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	64a2                	ld	s1,8(sp)
    80003262:	6902                	ld	s2,0(sp)
    80003264:	6105                	addi	sp,sp,32
    80003266:	8082                	ret
    panic("freeing free block");
    80003268:	00005517          	auipc	a0,0x5
    8000326c:	2d050513          	addi	a0,a0,720 # 80008538 <syscalls+0xf8>
    80003270:	ffffd097          	auipc	ra,0xffffd
    80003274:	2d8080e7          	jalr	728(ra) # 80000548 <panic>

0000000080003278 <balloc>:
{
    80003278:	711d                	addi	sp,sp,-96
    8000327a:	ec86                	sd	ra,88(sp)
    8000327c:	e8a2                	sd	s0,80(sp)
    8000327e:	e4a6                	sd	s1,72(sp)
    80003280:	e0ca                	sd	s2,64(sp)
    80003282:	fc4e                	sd	s3,56(sp)
    80003284:	f852                	sd	s4,48(sp)
    80003286:	f456                	sd	s5,40(sp)
    80003288:	f05a                	sd	s6,32(sp)
    8000328a:	ec5e                	sd	s7,24(sp)
    8000328c:	e862                	sd	s8,16(sp)
    8000328e:	e466                	sd	s9,8(sp)
    80003290:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003292:	0001d797          	auipc	a5,0x1d
    80003296:	3b27a783          	lw	a5,946(a5) # 80020644 <sb+0x4>
    8000329a:	cbd1                	beqz	a5,8000332e <balloc+0xb6>
    8000329c:	8baa                	mv	s7,a0
    8000329e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032a0:	0001db17          	auipc	s6,0x1d
    800032a4:	3a0b0b13          	addi	s6,s6,928 # 80020640 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032aa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ac:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032ae:	6c89                	lui	s9,0x2
    800032b0:	a831                	j	800032cc <balloc+0x54>
    brelse(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	e32080e7          	jalr	-462(ra) # 800030e6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032bc:	015c87bb          	addw	a5,s9,s5
    800032c0:	00078a9b          	sext.w	s5,a5
    800032c4:	004b2703          	lw	a4,4(s6)
    800032c8:	06eaf363          	bgeu	s5,a4,8000332e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032cc:	41fad79b          	sraiw	a5,s5,0x1f
    800032d0:	0137d79b          	srliw	a5,a5,0x13
    800032d4:	015787bb          	addw	a5,a5,s5
    800032d8:	40d7d79b          	sraiw	a5,a5,0xd
    800032dc:	01cb2583          	lw	a1,28(s6)
    800032e0:	9dbd                	addw	a1,a1,a5
    800032e2:	855e                	mv	a0,s7
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	cd2080e7          	jalr	-814(ra) # 80002fb6 <bread>
    800032ec:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ee:	004b2503          	lw	a0,4(s6)
    800032f2:	000a849b          	sext.w	s1,s5
    800032f6:	8662                	mv	a2,s8
    800032f8:	faa4fde3          	bgeu	s1,a0,800032b2 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032fc:	41f6579b          	sraiw	a5,a2,0x1f
    80003300:	01d7d69b          	srliw	a3,a5,0x1d
    80003304:	00c6873b          	addw	a4,a3,a2
    80003308:	00777793          	andi	a5,a4,7
    8000330c:	9f95                	subw	a5,a5,a3
    8000330e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003312:	4037571b          	sraiw	a4,a4,0x3
    80003316:	00e906b3          	add	a3,s2,a4
    8000331a:	0586c683          	lbu	a3,88(a3)
    8000331e:	00d7f5b3          	and	a1,a5,a3
    80003322:	cd91                	beqz	a1,8000333e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003324:	2605                	addiw	a2,a2,1
    80003326:	2485                	addiw	s1,s1,1
    80003328:	fd4618e3          	bne	a2,s4,800032f8 <balloc+0x80>
    8000332c:	b759                	j	800032b2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000332e:	00005517          	auipc	a0,0x5
    80003332:	22250513          	addi	a0,a0,546 # 80008550 <syscalls+0x110>
    80003336:	ffffd097          	auipc	ra,0xffffd
    8000333a:	212080e7          	jalr	530(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000333e:	974a                	add	a4,a4,s2
    80003340:	8fd5                	or	a5,a5,a3
    80003342:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003346:	854a                	mv	a0,s2
    80003348:	00001097          	auipc	ra,0x1
    8000334c:	002080e7          	jalr	2(ra) # 8000434a <log_write>
        brelse(bp);
    80003350:	854a                	mv	a0,s2
    80003352:	00000097          	auipc	ra,0x0
    80003356:	d94080e7          	jalr	-620(ra) # 800030e6 <brelse>
  bp = bread(dev, bno);
    8000335a:	85a6                	mv	a1,s1
    8000335c:	855e                	mv	a0,s7
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	c58080e7          	jalr	-936(ra) # 80002fb6 <bread>
    80003366:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003368:	40000613          	li	a2,1024
    8000336c:	4581                	li	a1,0
    8000336e:	05850513          	addi	a0,a0,88
    80003372:	ffffe097          	auipc	ra,0xffffe
    80003376:	a06080e7          	jalr	-1530(ra) # 80000d78 <memset>
  log_write(bp);
    8000337a:	854a                	mv	a0,s2
    8000337c:	00001097          	auipc	ra,0x1
    80003380:	fce080e7          	jalr	-50(ra) # 8000434a <log_write>
  brelse(bp);
    80003384:	854a                	mv	a0,s2
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	d60080e7          	jalr	-672(ra) # 800030e6 <brelse>
}
    8000338e:	8526                	mv	a0,s1
    80003390:	60e6                	ld	ra,88(sp)
    80003392:	6446                	ld	s0,80(sp)
    80003394:	64a6                	ld	s1,72(sp)
    80003396:	6906                	ld	s2,64(sp)
    80003398:	79e2                	ld	s3,56(sp)
    8000339a:	7a42                	ld	s4,48(sp)
    8000339c:	7aa2                	ld	s5,40(sp)
    8000339e:	7b02                	ld	s6,32(sp)
    800033a0:	6be2                	ld	s7,24(sp)
    800033a2:	6c42                	ld	s8,16(sp)
    800033a4:	6ca2                	ld	s9,8(sp)
    800033a6:	6125                	addi	sp,sp,96
    800033a8:	8082                	ret

00000000800033aa <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033aa:	7179                	addi	sp,sp,-48
    800033ac:	f406                	sd	ra,40(sp)
    800033ae:	f022                	sd	s0,32(sp)
    800033b0:	ec26                	sd	s1,24(sp)
    800033b2:	e84a                	sd	s2,16(sp)
    800033b4:	e44e                	sd	s3,8(sp)
    800033b6:	e052                	sd	s4,0(sp)
    800033b8:	1800                	addi	s0,sp,48
    800033ba:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033bc:	47ad                	li	a5,11
    800033be:	04b7fe63          	bgeu	a5,a1,8000341a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033c2:	ff45849b          	addiw	s1,a1,-12
    800033c6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ca:	0ff00793          	li	a5,255
    800033ce:	0ae7e363          	bltu	a5,a4,80003474 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033d2:	08052583          	lw	a1,128(a0)
    800033d6:	c5ad                	beqz	a1,80003440 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033d8:	00092503          	lw	a0,0(s2)
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	bda080e7          	jalr	-1062(ra) # 80002fb6 <bread>
    800033e4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033e6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ea:	02049593          	slli	a1,s1,0x20
    800033ee:	9181                	srli	a1,a1,0x20
    800033f0:	058a                	slli	a1,a1,0x2
    800033f2:	00b784b3          	add	s1,a5,a1
    800033f6:	0004a983          	lw	s3,0(s1)
    800033fa:	04098d63          	beqz	s3,80003454 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033fe:	8552                	mv	a0,s4
    80003400:	00000097          	auipc	ra,0x0
    80003404:	ce6080e7          	jalr	-794(ra) # 800030e6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003408:	854e                	mv	a0,s3
    8000340a:	70a2                	ld	ra,40(sp)
    8000340c:	7402                	ld	s0,32(sp)
    8000340e:	64e2                	ld	s1,24(sp)
    80003410:	6942                	ld	s2,16(sp)
    80003412:	69a2                	ld	s3,8(sp)
    80003414:	6a02                	ld	s4,0(sp)
    80003416:	6145                	addi	sp,sp,48
    80003418:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000341a:	02059493          	slli	s1,a1,0x20
    8000341e:	9081                	srli	s1,s1,0x20
    80003420:	048a                	slli	s1,s1,0x2
    80003422:	94aa                	add	s1,s1,a0
    80003424:	0504a983          	lw	s3,80(s1)
    80003428:	fe0990e3          	bnez	s3,80003408 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000342c:	4108                	lw	a0,0(a0)
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	e4a080e7          	jalr	-438(ra) # 80003278 <balloc>
    80003436:	0005099b          	sext.w	s3,a0
    8000343a:	0534a823          	sw	s3,80(s1)
    8000343e:	b7e9                	j	80003408 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003440:	4108                	lw	a0,0(a0)
    80003442:	00000097          	auipc	ra,0x0
    80003446:	e36080e7          	jalr	-458(ra) # 80003278 <balloc>
    8000344a:	0005059b          	sext.w	a1,a0
    8000344e:	08b92023          	sw	a1,128(s2)
    80003452:	b759                	j	800033d8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003454:	00092503          	lw	a0,0(s2)
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e20080e7          	jalr	-480(ra) # 80003278 <balloc>
    80003460:	0005099b          	sext.w	s3,a0
    80003464:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003468:	8552                	mv	a0,s4
    8000346a:	00001097          	auipc	ra,0x1
    8000346e:	ee0080e7          	jalr	-288(ra) # 8000434a <log_write>
    80003472:	b771                	j	800033fe <bmap+0x54>
  panic("bmap: out of range");
    80003474:	00005517          	auipc	a0,0x5
    80003478:	0f450513          	addi	a0,a0,244 # 80008568 <syscalls+0x128>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	0cc080e7          	jalr	204(ra) # 80000548 <panic>

0000000080003484 <iget>:
{
    80003484:	7179                	addi	sp,sp,-48
    80003486:	f406                	sd	ra,40(sp)
    80003488:	f022                	sd	s0,32(sp)
    8000348a:	ec26                	sd	s1,24(sp)
    8000348c:	e84a                	sd	s2,16(sp)
    8000348e:	e44e                	sd	s3,8(sp)
    80003490:	e052                	sd	s4,0(sp)
    80003492:	1800                	addi	s0,sp,48
    80003494:	89aa                	mv	s3,a0
    80003496:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003498:	0001d517          	auipc	a0,0x1d
    8000349c:	1c850513          	addi	a0,a0,456 # 80020660 <icache>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	7dc080e7          	jalr	2012(ra) # 80000c7c <acquire>
  empty = 0;
    800034a8:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034aa:	0001d497          	auipc	s1,0x1d
    800034ae:	1ce48493          	addi	s1,s1,462 # 80020678 <icache+0x18>
    800034b2:	0001f697          	auipc	a3,0x1f
    800034b6:	c5668693          	addi	a3,a3,-938 # 80022108 <log>
    800034ba:	a039                	j	800034c8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034bc:	02090b63          	beqz	s2,800034f2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034c0:	08848493          	addi	s1,s1,136
    800034c4:	02d48a63          	beq	s1,a3,800034f8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034c8:	449c                	lw	a5,8(s1)
    800034ca:	fef059e3          	blez	a5,800034bc <iget+0x38>
    800034ce:	4098                	lw	a4,0(s1)
    800034d0:	ff3716e3          	bne	a4,s3,800034bc <iget+0x38>
    800034d4:	40d8                	lw	a4,4(s1)
    800034d6:	ff4713e3          	bne	a4,s4,800034bc <iget+0x38>
      ip->ref++;
    800034da:	2785                	addiw	a5,a5,1
    800034dc:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034de:	0001d517          	auipc	a0,0x1d
    800034e2:	18250513          	addi	a0,a0,386 # 80020660 <icache>
    800034e6:	ffffe097          	auipc	ra,0xffffe
    800034ea:	84a080e7          	jalr	-1974(ra) # 80000d30 <release>
      return ip;
    800034ee:	8926                	mv	s2,s1
    800034f0:	a03d                	j	8000351e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f2:	f7f9                	bnez	a5,800034c0 <iget+0x3c>
    800034f4:	8926                	mv	s2,s1
    800034f6:	b7e9                	j	800034c0 <iget+0x3c>
  if(empty == 0)
    800034f8:	02090c63          	beqz	s2,80003530 <iget+0xac>
  ip->dev = dev;
    800034fc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003500:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003504:	4785                	li	a5,1
    80003506:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000350a:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000350e:	0001d517          	auipc	a0,0x1d
    80003512:	15250513          	addi	a0,a0,338 # 80020660 <icache>
    80003516:	ffffe097          	auipc	ra,0xffffe
    8000351a:	81a080e7          	jalr	-2022(ra) # 80000d30 <release>
}
    8000351e:	854a                	mv	a0,s2
    80003520:	70a2                	ld	ra,40(sp)
    80003522:	7402                	ld	s0,32(sp)
    80003524:	64e2                	ld	s1,24(sp)
    80003526:	6942                	ld	s2,16(sp)
    80003528:	69a2                	ld	s3,8(sp)
    8000352a:	6a02                	ld	s4,0(sp)
    8000352c:	6145                	addi	sp,sp,48
    8000352e:	8082                	ret
    panic("iget: no inodes");
    80003530:	00005517          	auipc	a0,0x5
    80003534:	05050513          	addi	a0,a0,80 # 80008580 <syscalls+0x140>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	010080e7          	jalr	16(ra) # 80000548 <panic>

0000000080003540 <fsinit>:
fsinit(int dev) {
    80003540:	7179                	addi	sp,sp,-48
    80003542:	f406                	sd	ra,40(sp)
    80003544:	f022                	sd	s0,32(sp)
    80003546:	ec26                	sd	s1,24(sp)
    80003548:	e84a                	sd	s2,16(sp)
    8000354a:	e44e                	sd	s3,8(sp)
    8000354c:	1800                	addi	s0,sp,48
    8000354e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003550:	4585                	li	a1,1
    80003552:	00000097          	auipc	ra,0x0
    80003556:	a64080e7          	jalr	-1436(ra) # 80002fb6 <bread>
    8000355a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000355c:	0001d997          	auipc	s3,0x1d
    80003560:	0e498993          	addi	s3,s3,228 # 80020640 <sb>
    80003564:	02000613          	li	a2,32
    80003568:	05850593          	addi	a1,a0,88
    8000356c:	854e                	mv	a0,s3
    8000356e:	ffffe097          	auipc	ra,0xffffe
    80003572:	86a080e7          	jalr	-1942(ra) # 80000dd8 <memmove>
  brelse(bp);
    80003576:	8526                	mv	a0,s1
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	b6e080e7          	jalr	-1170(ra) # 800030e6 <brelse>
  if(sb.magic != FSMAGIC)
    80003580:	0009a703          	lw	a4,0(s3)
    80003584:	102037b7          	lui	a5,0x10203
    80003588:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000358c:	02f71263          	bne	a4,a5,800035b0 <fsinit+0x70>
  initlog(dev, &sb);
    80003590:	0001d597          	auipc	a1,0x1d
    80003594:	0b058593          	addi	a1,a1,176 # 80020640 <sb>
    80003598:	854a                	mv	a0,s2
    8000359a:	00001097          	auipc	ra,0x1
    8000359e:	b38080e7          	jalr	-1224(ra) # 800040d2 <initlog>
}
    800035a2:	70a2                	ld	ra,40(sp)
    800035a4:	7402                	ld	s0,32(sp)
    800035a6:	64e2                	ld	s1,24(sp)
    800035a8:	6942                	ld	s2,16(sp)
    800035aa:	69a2                	ld	s3,8(sp)
    800035ac:	6145                	addi	sp,sp,48
    800035ae:	8082                	ret
    panic("invalid file system");
    800035b0:	00005517          	auipc	a0,0x5
    800035b4:	fe050513          	addi	a0,a0,-32 # 80008590 <syscalls+0x150>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	f90080e7          	jalr	-112(ra) # 80000548 <panic>

00000000800035c0 <iinit>:
{
    800035c0:	7179                	addi	sp,sp,-48
    800035c2:	f406                	sd	ra,40(sp)
    800035c4:	f022                	sd	s0,32(sp)
    800035c6:	ec26                	sd	s1,24(sp)
    800035c8:	e84a                	sd	s2,16(sp)
    800035ca:	e44e                	sd	s3,8(sp)
    800035cc:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035ce:	00005597          	auipc	a1,0x5
    800035d2:	fda58593          	addi	a1,a1,-38 # 800085a8 <syscalls+0x168>
    800035d6:	0001d517          	auipc	a0,0x1d
    800035da:	08a50513          	addi	a0,a0,138 # 80020660 <icache>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	60e080e7          	jalr	1550(ra) # 80000bec <initlock>
  for(i = 0; i < NINODE; i++) {
    800035e6:	0001d497          	auipc	s1,0x1d
    800035ea:	0a248493          	addi	s1,s1,162 # 80020688 <icache+0x28>
    800035ee:	0001f997          	auipc	s3,0x1f
    800035f2:	b2a98993          	addi	s3,s3,-1238 # 80022118 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035f6:	00005917          	auipc	s2,0x5
    800035fa:	fba90913          	addi	s2,s2,-70 # 800085b0 <syscalls+0x170>
    800035fe:	85ca                	mv	a1,s2
    80003600:	8526                	mv	a0,s1
    80003602:	00001097          	auipc	ra,0x1
    80003606:	e36080e7          	jalr	-458(ra) # 80004438 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000360a:	08848493          	addi	s1,s1,136
    8000360e:	ff3498e3          	bne	s1,s3,800035fe <iinit+0x3e>
}
    80003612:	70a2                	ld	ra,40(sp)
    80003614:	7402                	ld	s0,32(sp)
    80003616:	64e2                	ld	s1,24(sp)
    80003618:	6942                	ld	s2,16(sp)
    8000361a:	69a2                	ld	s3,8(sp)
    8000361c:	6145                	addi	sp,sp,48
    8000361e:	8082                	ret

0000000080003620 <ialloc>:
{
    80003620:	715d                	addi	sp,sp,-80
    80003622:	e486                	sd	ra,72(sp)
    80003624:	e0a2                	sd	s0,64(sp)
    80003626:	fc26                	sd	s1,56(sp)
    80003628:	f84a                	sd	s2,48(sp)
    8000362a:	f44e                	sd	s3,40(sp)
    8000362c:	f052                	sd	s4,32(sp)
    8000362e:	ec56                	sd	s5,24(sp)
    80003630:	e85a                	sd	s6,16(sp)
    80003632:	e45e                	sd	s7,8(sp)
    80003634:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003636:	0001d717          	auipc	a4,0x1d
    8000363a:	01672703          	lw	a4,22(a4) # 8002064c <sb+0xc>
    8000363e:	4785                	li	a5,1
    80003640:	04e7fa63          	bgeu	a5,a4,80003694 <ialloc+0x74>
    80003644:	8aaa                	mv	s5,a0
    80003646:	8bae                	mv	s7,a1
    80003648:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000364a:	0001da17          	auipc	s4,0x1d
    8000364e:	ff6a0a13          	addi	s4,s4,-10 # 80020640 <sb>
    80003652:	00048b1b          	sext.w	s6,s1
    80003656:	0044d593          	srli	a1,s1,0x4
    8000365a:	018a2783          	lw	a5,24(s4)
    8000365e:	9dbd                	addw	a1,a1,a5
    80003660:	8556                	mv	a0,s5
    80003662:	00000097          	auipc	ra,0x0
    80003666:	954080e7          	jalr	-1708(ra) # 80002fb6 <bread>
    8000366a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000366c:	05850993          	addi	s3,a0,88
    80003670:	00f4f793          	andi	a5,s1,15
    80003674:	079a                	slli	a5,a5,0x6
    80003676:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003678:	00099783          	lh	a5,0(s3)
    8000367c:	c785                	beqz	a5,800036a4 <ialloc+0x84>
    brelse(bp);
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	a68080e7          	jalr	-1432(ra) # 800030e6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003686:	0485                	addi	s1,s1,1
    80003688:	00ca2703          	lw	a4,12(s4)
    8000368c:	0004879b          	sext.w	a5,s1
    80003690:	fce7e1e3          	bltu	a5,a4,80003652 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003694:	00005517          	auipc	a0,0x5
    80003698:	f2450513          	addi	a0,a0,-220 # 800085b8 <syscalls+0x178>
    8000369c:	ffffd097          	auipc	ra,0xffffd
    800036a0:	eac080e7          	jalr	-340(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800036a4:	04000613          	li	a2,64
    800036a8:	4581                	li	a1,0
    800036aa:	854e                	mv	a0,s3
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	6cc080e7          	jalr	1740(ra) # 80000d78 <memset>
      dip->type = type;
    800036b4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036b8:	854a                	mv	a0,s2
    800036ba:	00001097          	auipc	ra,0x1
    800036be:	c90080e7          	jalr	-880(ra) # 8000434a <log_write>
      brelse(bp);
    800036c2:	854a                	mv	a0,s2
    800036c4:	00000097          	auipc	ra,0x0
    800036c8:	a22080e7          	jalr	-1502(ra) # 800030e6 <brelse>
      return iget(dev, inum);
    800036cc:	85da                	mv	a1,s6
    800036ce:	8556                	mv	a0,s5
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	db4080e7          	jalr	-588(ra) # 80003484 <iget>
}
    800036d8:	60a6                	ld	ra,72(sp)
    800036da:	6406                	ld	s0,64(sp)
    800036dc:	74e2                	ld	s1,56(sp)
    800036de:	7942                	ld	s2,48(sp)
    800036e0:	79a2                	ld	s3,40(sp)
    800036e2:	7a02                	ld	s4,32(sp)
    800036e4:	6ae2                	ld	s5,24(sp)
    800036e6:	6b42                	ld	s6,16(sp)
    800036e8:	6ba2                	ld	s7,8(sp)
    800036ea:	6161                	addi	sp,sp,80
    800036ec:	8082                	ret

00000000800036ee <iupdate>:
{
    800036ee:	1101                	addi	sp,sp,-32
    800036f0:	ec06                	sd	ra,24(sp)
    800036f2:	e822                	sd	s0,16(sp)
    800036f4:	e426                	sd	s1,8(sp)
    800036f6:	e04a                	sd	s2,0(sp)
    800036f8:	1000                	addi	s0,sp,32
    800036fa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036fc:	415c                	lw	a5,4(a0)
    800036fe:	0047d79b          	srliw	a5,a5,0x4
    80003702:	0001d597          	auipc	a1,0x1d
    80003706:	f565a583          	lw	a1,-170(a1) # 80020658 <sb+0x18>
    8000370a:	9dbd                	addw	a1,a1,a5
    8000370c:	4108                	lw	a0,0(a0)
    8000370e:	00000097          	auipc	ra,0x0
    80003712:	8a8080e7          	jalr	-1880(ra) # 80002fb6 <bread>
    80003716:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003718:	05850793          	addi	a5,a0,88
    8000371c:	40c8                	lw	a0,4(s1)
    8000371e:	893d                	andi	a0,a0,15
    80003720:	051a                	slli	a0,a0,0x6
    80003722:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003724:	04449703          	lh	a4,68(s1)
    80003728:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000372c:	04649703          	lh	a4,70(s1)
    80003730:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003734:	04849703          	lh	a4,72(s1)
    80003738:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000373c:	04a49703          	lh	a4,74(s1)
    80003740:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003744:	44f8                	lw	a4,76(s1)
    80003746:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003748:	03400613          	li	a2,52
    8000374c:	05048593          	addi	a1,s1,80
    80003750:	0531                	addi	a0,a0,12
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	686080e7          	jalr	1670(ra) # 80000dd8 <memmove>
  log_write(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	bee080e7          	jalr	-1042(ra) # 8000434a <log_write>
  brelse(bp);
    80003764:	854a                	mv	a0,s2
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	980080e7          	jalr	-1664(ra) # 800030e6 <brelse>
}
    8000376e:	60e2                	ld	ra,24(sp)
    80003770:	6442                	ld	s0,16(sp)
    80003772:	64a2                	ld	s1,8(sp)
    80003774:	6902                	ld	s2,0(sp)
    80003776:	6105                	addi	sp,sp,32
    80003778:	8082                	ret

000000008000377a <idup>:
{
    8000377a:	1101                	addi	sp,sp,-32
    8000377c:	ec06                	sd	ra,24(sp)
    8000377e:	e822                	sd	s0,16(sp)
    80003780:	e426                	sd	s1,8(sp)
    80003782:	1000                	addi	s0,sp,32
    80003784:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003786:	0001d517          	auipc	a0,0x1d
    8000378a:	eda50513          	addi	a0,a0,-294 # 80020660 <icache>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	4ee080e7          	jalr	1262(ra) # 80000c7c <acquire>
  ip->ref++;
    80003796:	449c                	lw	a5,8(s1)
    80003798:	2785                	addiw	a5,a5,1
    8000379a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000379c:	0001d517          	auipc	a0,0x1d
    800037a0:	ec450513          	addi	a0,a0,-316 # 80020660 <icache>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	58c080e7          	jalr	1420(ra) # 80000d30 <release>
}
    800037ac:	8526                	mv	a0,s1
    800037ae:	60e2                	ld	ra,24(sp)
    800037b0:	6442                	ld	s0,16(sp)
    800037b2:	64a2                	ld	s1,8(sp)
    800037b4:	6105                	addi	sp,sp,32
    800037b6:	8082                	ret

00000000800037b8 <ilock>:
{
    800037b8:	1101                	addi	sp,sp,-32
    800037ba:	ec06                	sd	ra,24(sp)
    800037bc:	e822                	sd	s0,16(sp)
    800037be:	e426                	sd	s1,8(sp)
    800037c0:	e04a                	sd	s2,0(sp)
    800037c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037c4:	c115                	beqz	a0,800037e8 <ilock+0x30>
    800037c6:	84aa                	mv	s1,a0
    800037c8:	451c                	lw	a5,8(a0)
    800037ca:	00f05f63          	blez	a5,800037e8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037ce:	0541                	addi	a0,a0,16
    800037d0:	00001097          	auipc	ra,0x1
    800037d4:	ca2080e7          	jalr	-862(ra) # 80004472 <acquiresleep>
  if(ip->valid == 0){
    800037d8:	40bc                	lw	a5,64(s1)
    800037da:	cf99                	beqz	a5,800037f8 <ilock+0x40>
}
    800037dc:	60e2                	ld	ra,24(sp)
    800037de:	6442                	ld	s0,16(sp)
    800037e0:	64a2                	ld	s1,8(sp)
    800037e2:	6902                	ld	s2,0(sp)
    800037e4:	6105                	addi	sp,sp,32
    800037e6:	8082                	ret
    panic("ilock");
    800037e8:	00005517          	auipc	a0,0x5
    800037ec:	de850513          	addi	a0,a0,-536 # 800085d0 <syscalls+0x190>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	d58080e7          	jalr	-680(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f8:	40dc                	lw	a5,4(s1)
    800037fa:	0047d79b          	srliw	a5,a5,0x4
    800037fe:	0001d597          	auipc	a1,0x1d
    80003802:	e5a5a583          	lw	a1,-422(a1) # 80020658 <sb+0x18>
    80003806:	9dbd                	addw	a1,a1,a5
    80003808:	4088                	lw	a0,0(s1)
    8000380a:	fffff097          	auipc	ra,0xfffff
    8000380e:	7ac080e7          	jalr	1964(ra) # 80002fb6 <bread>
    80003812:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003814:	05850593          	addi	a1,a0,88
    80003818:	40dc                	lw	a5,4(s1)
    8000381a:	8bbd                	andi	a5,a5,15
    8000381c:	079a                	slli	a5,a5,0x6
    8000381e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003820:	00059783          	lh	a5,0(a1)
    80003824:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003828:	00259783          	lh	a5,2(a1)
    8000382c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003830:	00459783          	lh	a5,4(a1)
    80003834:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003838:	00659783          	lh	a5,6(a1)
    8000383c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003840:	459c                	lw	a5,8(a1)
    80003842:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003844:	03400613          	li	a2,52
    80003848:	05b1                	addi	a1,a1,12
    8000384a:	05048513          	addi	a0,s1,80
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	58a080e7          	jalr	1418(ra) # 80000dd8 <memmove>
    brelse(bp);
    80003856:	854a                	mv	a0,s2
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	88e080e7          	jalr	-1906(ra) # 800030e6 <brelse>
    ip->valid = 1;
    80003860:	4785                	li	a5,1
    80003862:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003864:	04449783          	lh	a5,68(s1)
    80003868:	fbb5                	bnez	a5,800037dc <ilock+0x24>
      panic("ilock: no type");
    8000386a:	00005517          	auipc	a0,0x5
    8000386e:	d6e50513          	addi	a0,a0,-658 # 800085d8 <syscalls+0x198>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	cd6080e7          	jalr	-810(ra) # 80000548 <panic>

000000008000387a <iunlock>:
{
    8000387a:	1101                	addi	sp,sp,-32
    8000387c:	ec06                	sd	ra,24(sp)
    8000387e:	e822                	sd	s0,16(sp)
    80003880:	e426                	sd	s1,8(sp)
    80003882:	e04a                	sd	s2,0(sp)
    80003884:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003886:	c905                	beqz	a0,800038b6 <iunlock+0x3c>
    80003888:	84aa                	mv	s1,a0
    8000388a:	01050913          	addi	s2,a0,16
    8000388e:	854a                	mv	a0,s2
    80003890:	00001097          	auipc	ra,0x1
    80003894:	c7c080e7          	jalr	-900(ra) # 8000450c <holdingsleep>
    80003898:	cd19                	beqz	a0,800038b6 <iunlock+0x3c>
    8000389a:	449c                	lw	a5,8(s1)
    8000389c:	00f05d63          	blez	a5,800038b6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038a0:	854a                	mv	a0,s2
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	c26080e7          	jalr	-986(ra) # 800044c8 <releasesleep>
}
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	64a2                	ld	s1,8(sp)
    800038b0:	6902                	ld	s2,0(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret
    panic("iunlock");
    800038b6:	00005517          	auipc	a0,0x5
    800038ba:	d3250513          	addi	a0,a0,-718 # 800085e8 <syscalls+0x1a8>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	c8a080e7          	jalr	-886(ra) # 80000548 <panic>

00000000800038c6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038c6:	7179                	addi	sp,sp,-48
    800038c8:	f406                	sd	ra,40(sp)
    800038ca:	f022                	sd	s0,32(sp)
    800038cc:	ec26                	sd	s1,24(sp)
    800038ce:	e84a                	sd	s2,16(sp)
    800038d0:	e44e                	sd	s3,8(sp)
    800038d2:	e052                	sd	s4,0(sp)
    800038d4:	1800                	addi	s0,sp,48
    800038d6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038d8:	05050493          	addi	s1,a0,80
    800038dc:	08050913          	addi	s2,a0,128
    800038e0:	a021                	j	800038e8 <itrunc+0x22>
    800038e2:	0491                	addi	s1,s1,4
    800038e4:	01248d63          	beq	s1,s2,800038fe <itrunc+0x38>
    if(ip->addrs[i]){
    800038e8:	408c                	lw	a1,0(s1)
    800038ea:	dde5                	beqz	a1,800038e2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ec:	0009a503          	lw	a0,0(s3)
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	90c080e7          	jalr	-1780(ra) # 800031fc <bfree>
      ip->addrs[i] = 0;
    800038f8:	0004a023          	sw	zero,0(s1)
    800038fc:	b7dd                	j	800038e2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038fe:	0809a583          	lw	a1,128(s3)
    80003902:	e185                	bnez	a1,80003922 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003904:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003908:	854e                	mv	a0,s3
    8000390a:	00000097          	auipc	ra,0x0
    8000390e:	de4080e7          	jalr	-540(ra) # 800036ee <iupdate>
}
    80003912:	70a2                	ld	ra,40(sp)
    80003914:	7402                	ld	s0,32(sp)
    80003916:	64e2                	ld	s1,24(sp)
    80003918:	6942                	ld	s2,16(sp)
    8000391a:	69a2                	ld	s3,8(sp)
    8000391c:	6a02                	ld	s4,0(sp)
    8000391e:	6145                	addi	sp,sp,48
    80003920:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003922:	0009a503          	lw	a0,0(s3)
    80003926:	fffff097          	auipc	ra,0xfffff
    8000392a:	690080e7          	jalr	1680(ra) # 80002fb6 <bread>
    8000392e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003930:	05850493          	addi	s1,a0,88
    80003934:	45850913          	addi	s2,a0,1112
    80003938:	a811                	j	8000394c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000393a:	0009a503          	lw	a0,0(s3)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	8be080e7          	jalr	-1858(ra) # 800031fc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003946:	0491                	addi	s1,s1,4
    80003948:	01248563          	beq	s1,s2,80003952 <itrunc+0x8c>
      if(a[j])
    8000394c:	408c                	lw	a1,0(s1)
    8000394e:	dde5                	beqz	a1,80003946 <itrunc+0x80>
    80003950:	b7ed                	j	8000393a <itrunc+0x74>
    brelse(bp);
    80003952:	8552                	mv	a0,s4
    80003954:	fffff097          	auipc	ra,0xfffff
    80003958:	792080e7          	jalr	1938(ra) # 800030e6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000395c:	0809a583          	lw	a1,128(s3)
    80003960:	0009a503          	lw	a0,0(s3)
    80003964:	00000097          	auipc	ra,0x0
    80003968:	898080e7          	jalr	-1896(ra) # 800031fc <bfree>
    ip->addrs[NDIRECT] = 0;
    8000396c:	0809a023          	sw	zero,128(s3)
    80003970:	bf51                	j	80003904 <itrunc+0x3e>

0000000080003972 <iput>:
{
    80003972:	1101                	addi	sp,sp,-32
    80003974:	ec06                	sd	ra,24(sp)
    80003976:	e822                	sd	s0,16(sp)
    80003978:	e426                	sd	s1,8(sp)
    8000397a:	e04a                	sd	s2,0(sp)
    8000397c:	1000                	addi	s0,sp,32
    8000397e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003980:	0001d517          	auipc	a0,0x1d
    80003984:	ce050513          	addi	a0,a0,-800 # 80020660 <icache>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	2f4080e7          	jalr	756(ra) # 80000c7c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003990:	4498                	lw	a4,8(s1)
    80003992:	4785                	li	a5,1
    80003994:	02f70363          	beq	a4,a5,800039ba <iput+0x48>
  ip->ref--;
    80003998:	449c                	lw	a5,8(s1)
    8000399a:	37fd                	addiw	a5,a5,-1
    8000399c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000399e:	0001d517          	auipc	a0,0x1d
    800039a2:	cc250513          	addi	a0,a0,-830 # 80020660 <icache>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	38a080e7          	jalr	906(ra) # 80000d30 <release>
}
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	64a2                	ld	s1,8(sp)
    800039b4:	6902                	ld	s2,0(sp)
    800039b6:	6105                	addi	sp,sp,32
    800039b8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ba:	40bc                	lw	a5,64(s1)
    800039bc:	dff1                	beqz	a5,80003998 <iput+0x26>
    800039be:	04a49783          	lh	a5,74(s1)
    800039c2:	fbf9                	bnez	a5,80003998 <iput+0x26>
    acquiresleep(&ip->lock);
    800039c4:	01048913          	addi	s2,s1,16
    800039c8:	854a                	mv	a0,s2
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	aa8080e7          	jalr	-1368(ra) # 80004472 <acquiresleep>
    release(&icache.lock);
    800039d2:	0001d517          	auipc	a0,0x1d
    800039d6:	c8e50513          	addi	a0,a0,-882 # 80020660 <icache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	356080e7          	jalr	854(ra) # 80000d30 <release>
    itrunc(ip);
    800039e2:	8526                	mv	a0,s1
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	ee2080e7          	jalr	-286(ra) # 800038c6 <itrunc>
    ip->type = 0;
    800039ec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039f0:	8526                	mv	a0,s1
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	cfc080e7          	jalr	-772(ra) # 800036ee <iupdate>
    ip->valid = 0;
    800039fa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039fe:	854a                	mv	a0,s2
    80003a00:	00001097          	auipc	ra,0x1
    80003a04:	ac8080e7          	jalr	-1336(ra) # 800044c8 <releasesleep>
    acquire(&icache.lock);
    80003a08:	0001d517          	auipc	a0,0x1d
    80003a0c:	c5850513          	addi	a0,a0,-936 # 80020660 <icache>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	26c080e7          	jalr	620(ra) # 80000c7c <acquire>
    80003a18:	b741                	j	80003998 <iput+0x26>

0000000080003a1a <iunlockput>:
{
    80003a1a:	1101                	addi	sp,sp,-32
    80003a1c:	ec06                	sd	ra,24(sp)
    80003a1e:	e822                	sd	s0,16(sp)
    80003a20:	e426                	sd	s1,8(sp)
    80003a22:	1000                	addi	s0,sp,32
    80003a24:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	e54080e7          	jalr	-428(ra) # 8000387a <iunlock>
  iput(ip);
    80003a2e:	8526                	mv	a0,s1
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	f42080e7          	jalr	-190(ra) # 80003972 <iput>
}
    80003a38:	60e2                	ld	ra,24(sp)
    80003a3a:	6442                	ld	s0,16(sp)
    80003a3c:	64a2                	ld	s1,8(sp)
    80003a3e:	6105                	addi	sp,sp,32
    80003a40:	8082                	ret

0000000080003a42 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a42:	1141                	addi	sp,sp,-16
    80003a44:	e422                	sd	s0,8(sp)
    80003a46:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a48:	411c                	lw	a5,0(a0)
    80003a4a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a4c:	415c                	lw	a5,4(a0)
    80003a4e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a50:	04451783          	lh	a5,68(a0)
    80003a54:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a58:	04a51783          	lh	a5,74(a0)
    80003a5c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a60:	04c56783          	lwu	a5,76(a0)
    80003a64:	e99c                	sd	a5,16(a1)
}
    80003a66:	6422                	ld	s0,8(sp)
    80003a68:	0141                	addi	sp,sp,16
    80003a6a:	8082                	ret

0000000080003a6c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a6c:	457c                	lw	a5,76(a0)
    80003a6e:	0ed7e863          	bltu	a5,a3,80003b5e <readi+0xf2>
{
    80003a72:	7159                	addi	sp,sp,-112
    80003a74:	f486                	sd	ra,104(sp)
    80003a76:	f0a2                	sd	s0,96(sp)
    80003a78:	eca6                	sd	s1,88(sp)
    80003a7a:	e8ca                	sd	s2,80(sp)
    80003a7c:	e4ce                	sd	s3,72(sp)
    80003a7e:	e0d2                	sd	s4,64(sp)
    80003a80:	fc56                	sd	s5,56(sp)
    80003a82:	f85a                	sd	s6,48(sp)
    80003a84:	f45e                	sd	s7,40(sp)
    80003a86:	f062                	sd	s8,32(sp)
    80003a88:	ec66                	sd	s9,24(sp)
    80003a8a:	e86a                	sd	s10,16(sp)
    80003a8c:	e46e                	sd	s11,8(sp)
    80003a8e:	1880                	addi	s0,sp,112
    80003a90:	8baa                	mv	s7,a0
    80003a92:	8c2e                	mv	s8,a1
    80003a94:	8ab2                	mv	s5,a2
    80003a96:	84b6                	mv	s1,a3
    80003a98:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a9a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a9c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a9e:	08d76f63          	bltu	a4,a3,80003b3c <readi+0xd0>
  if(off + n > ip->size)
    80003aa2:	00e7f463          	bgeu	a5,a4,80003aaa <readi+0x3e>
    n = ip->size - off;
    80003aa6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aaa:	0a0b0863          	beqz	s6,80003b5a <readi+0xee>
    80003aae:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ab4:	5cfd                	li	s9,-1
    80003ab6:	a82d                	j	80003af0 <readi+0x84>
    80003ab8:	020a1d93          	slli	s11,s4,0x20
    80003abc:	020ddd93          	srli	s11,s11,0x20
    80003ac0:	05890613          	addi	a2,s2,88
    80003ac4:	86ee                	mv	a3,s11
    80003ac6:	963a                	add	a2,a2,a4
    80003ac8:	85d6                	mv	a1,s5
    80003aca:	8562                	mv	a0,s8
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	a46080e7          	jalr	-1466(ra) # 80002512 <either_copyout>
    80003ad4:	05950d63          	beq	a0,s9,80003b2e <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003ad8:	854a                	mv	a0,s2
    80003ada:	fffff097          	auipc	ra,0xfffff
    80003ade:	60c080e7          	jalr	1548(ra) # 800030e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae2:	013a09bb          	addw	s3,s4,s3
    80003ae6:	009a04bb          	addw	s1,s4,s1
    80003aea:	9aee                	add	s5,s5,s11
    80003aec:	0569f663          	bgeu	s3,s6,80003b38 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003af0:	000ba903          	lw	s2,0(s7)
    80003af4:	00a4d59b          	srliw	a1,s1,0xa
    80003af8:	855e                	mv	a0,s7
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	8b0080e7          	jalr	-1872(ra) # 800033aa <bmap>
    80003b02:	0005059b          	sext.w	a1,a0
    80003b06:	854a                	mv	a0,s2
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	4ae080e7          	jalr	1198(ra) # 80002fb6 <bread>
    80003b10:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b12:	3ff4f713          	andi	a4,s1,1023
    80003b16:	40ed07bb          	subw	a5,s10,a4
    80003b1a:	413b06bb          	subw	a3,s6,s3
    80003b1e:	8a3e                	mv	s4,a5
    80003b20:	2781                	sext.w	a5,a5
    80003b22:	0006861b          	sext.w	a2,a3
    80003b26:	f8f679e3          	bgeu	a2,a5,80003ab8 <readi+0x4c>
    80003b2a:	8a36                	mv	s4,a3
    80003b2c:	b771                	j	80003ab8 <readi+0x4c>
      brelse(bp);
    80003b2e:	854a                	mv	a0,s2
    80003b30:	fffff097          	auipc	ra,0xfffff
    80003b34:	5b6080e7          	jalr	1462(ra) # 800030e6 <brelse>
  }
  return tot;
    80003b38:	0009851b          	sext.w	a0,s3
}
    80003b3c:	70a6                	ld	ra,104(sp)
    80003b3e:	7406                	ld	s0,96(sp)
    80003b40:	64e6                	ld	s1,88(sp)
    80003b42:	6946                	ld	s2,80(sp)
    80003b44:	69a6                	ld	s3,72(sp)
    80003b46:	6a06                	ld	s4,64(sp)
    80003b48:	7ae2                	ld	s5,56(sp)
    80003b4a:	7b42                	ld	s6,48(sp)
    80003b4c:	7ba2                	ld	s7,40(sp)
    80003b4e:	7c02                	ld	s8,32(sp)
    80003b50:	6ce2                	ld	s9,24(sp)
    80003b52:	6d42                	ld	s10,16(sp)
    80003b54:	6da2                	ld	s11,8(sp)
    80003b56:	6165                	addi	sp,sp,112
    80003b58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5a:	89da                	mv	s3,s6
    80003b5c:	bff1                	j	80003b38 <readi+0xcc>
    return 0;
    80003b5e:	4501                	li	a0,0
}
    80003b60:	8082                	ret

0000000080003b62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b62:	457c                	lw	a5,76(a0)
    80003b64:	10d7e663          	bltu	a5,a3,80003c70 <writei+0x10e>
{
    80003b68:	7159                	addi	sp,sp,-112
    80003b6a:	f486                	sd	ra,104(sp)
    80003b6c:	f0a2                	sd	s0,96(sp)
    80003b6e:	eca6                	sd	s1,88(sp)
    80003b70:	e8ca                	sd	s2,80(sp)
    80003b72:	e4ce                	sd	s3,72(sp)
    80003b74:	e0d2                	sd	s4,64(sp)
    80003b76:	fc56                	sd	s5,56(sp)
    80003b78:	f85a                	sd	s6,48(sp)
    80003b7a:	f45e                	sd	s7,40(sp)
    80003b7c:	f062                	sd	s8,32(sp)
    80003b7e:	ec66                	sd	s9,24(sp)
    80003b80:	e86a                	sd	s10,16(sp)
    80003b82:	e46e                	sd	s11,8(sp)
    80003b84:	1880                	addi	s0,sp,112
    80003b86:	8baa                	mv	s7,a0
    80003b88:	8c2e                	mv	s8,a1
    80003b8a:	8ab2                	mv	s5,a2
    80003b8c:	8936                	mv	s2,a3
    80003b8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b90:	00e687bb          	addw	a5,a3,a4
    80003b94:	0ed7e063          	bltu	a5,a3,80003c74 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b98:	00043737          	lui	a4,0x43
    80003b9c:	0cf76e63          	bltu	a4,a5,80003c78 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	0a0b0763          	beqz	s6,80003c4e <writei+0xec>
    80003ba4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003baa:	5cfd                	li	s9,-1
    80003bac:	a091                	j	80003bf0 <writei+0x8e>
    80003bae:	02099d93          	slli	s11,s3,0x20
    80003bb2:	020ddd93          	srli	s11,s11,0x20
    80003bb6:	05848513          	addi	a0,s1,88
    80003bba:	86ee                	mv	a3,s11
    80003bbc:	8656                	mv	a2,s5
    80003bbe:	85e2                	mv	a1,s8
    80003bc0:	953a                	add	a0,a0,a4
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	9a6080e7          	jalr	-1626(ra) # 80002568 <either_copyin>
    80003bca:	07950263          	beq	a0,s9,80003c2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bce:	8526                	mv	a0,s1
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	77a080e7          	jalr	1914(ra) # 8000434a <log_write>
    brelse(bp);
    80003bd8:	8526                	mv	a0,s1
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	50c080e7          	jalr	1292(ra) # 800030e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be2:	01498a3b          	addw	s4,s3,s4
    80003be6:	0129893b          	addw	s2,s3,s2
    80003bea:	9aee                	add	s5,s5,s11
    80003bec:	056a7663          	bgeu	s4,s6,80003c38 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf0:	000ba483          	lw	s1,0(s7)
    80003bf4:	00a9559b          	srliw	a1,s2,0xa
    80003bf8:	855e                	mv	a0,s7
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	7b0080e7          	jalr	1968(ra) # 800033aa <bmap>
    80003c02:	0005059b          	sext.w	a1,a0
    80003c06:	8526                	mv	a0,s1
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	3ae080e7          	jalr	942(ra) # 80002fb6 <bread>
    80003c10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c12:	3ff97713          	andi	a4,s2,1023
    80003c16:	40ed07bb          	subw	a5,s10,a4
    80003c1a:	414b06bb          	subw	a3,s6,s4
    80003c1e:	89be                	mv	s3,a5
    80003c20:	2781                	sext.w	a5,a5
    80003c22:	0006861b          	sext.w	a2,a3
    80003c26:	f8f674e3          	bgeu	a2,a5,80003bae <writei+0x4c>
    80003c2a:	89b6                	mv	s3,a3
    80003c2c:	b749                	j	80003bae <writei+0x4c>
      brelse(bp);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	4b6080e7          	jalr	1206(ra) # 800030e6 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c38:	04cba783          	lw	a5,76(s7)
    80003c3c:	0127f463          	bgeu	a5,s2,80003c44 <writei+0xe2>
      ip->size = off;
    80003c40:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c44:	855e                	mv	a0,s7
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	aa8080e7          	jalr	-1368(ra) # 800036ee <iupdate>
  }

  return n;
    80003c4e:	000b051b          	sext.w	a0,s6
}
    80003c52:	70a6                	ld	ra,104(sp)
    80003c54:	7406                	ld	s0,96(sp)
    80003c56:	64e6                	ld	s1,88(sp)
    80003c58:	6946                	ld	s2,80(sp)
    80003c5a:	69a6                	ld	s3,72(sp)
    80003c5c:	6a06                	ld	s4,64(sp)
    80003c5e:	7ae2                	ld	s5,56(sp)
    80003c60:	7b42                	ld	s6,48(sp)
    80003c62:	7ba2                	ld	s7,40(sp)
    80003c64:	7c02                	ld	s8,32(sp)
    80003c66:	6ce2                	ld	s9,24(sp)
    80003c68:	6d42                	ld	s10,16(sp)
    80003c6a:	6da2                	ld	s11,8(sp)
    80003c6c:	6165                	addi	sp,sp,112
    80003c6e:	8082                	ret
    return -1;
    80003c70:	557d                	li	a0,-1
}
    80003c72:	8082                	ret
    return -1;
    80003c74:	557d                	li	a0,-1
    80003c76:	bff1                	j	80003c52 <writei+0xf0>
    return -1;
    80003c78:	557d                	li	a0,-1
    80003c7a:	bfe1                	j	80003c52 <writei+0xf0>

0000000080003c7c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c7c:	1141                	addi	sp,sp,-16
    80003c7e:	e406                	sd	ra,8(sp)
    80003c80:	e022                	sd	s0,0(sp)
    80003c82:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c84:	4639                	li	a2,14
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	1ce080e7          	jalr	462(ra) # 80000e54 <strncmp>
}
    80003c8e:	60a2                	ld	ra,8(sp)
    80003c90:	6402                	ld	s0,0(sp)
    80003c92:	0141                	addi	sp,sp,16
    80003c94:	8082                	ret

0000000080003c96 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c96:	7139                	addi	sp,sp,-64
    80003c98:	fc06                	sd	ra,56(sp)
    80003c9a:	f822                	sd	s0,48(sp)
    80003c9c:	f426                	sd	s1,40(sp)
    80003c9e:	f04a                	sd	s2,32(sp)
    80003ca0:	ec4e                	sd	s3,24(sp)
    80003ca2:	e852                	sd	s4,16(sp)
    80003ca4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ca6:	04451703          	lh	a4,68(a0)
    80003caa:	4785                	li	a5,1
    80003cac:	00f71a63          	bne	a4,a5,80003cc0 <dirlookup+0x2a>
    80003cb0:	892a                	mv	s2,a0
    80003cb2:	89ae                	mv	s3,a1
    80003cb4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb6:	457c                	lw	a5,76(a0)
    80003cb8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cba:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cbc:	e79d                	bnez	a5,80003cea <dirlookup+0x54>
    80003cbe:	a8a5                	j	80003d36 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cc0:	00005517          	auipc	a0,0x5
    80003cc4:	93050513          	addi	a0,a0,-1744 # 800085f0 <syscalls+0x1b0>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	880080e7          	jalr	-1920(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003cd0:	00005517          	auipc	a0,0x5
    80003cd4:	93850513          	addi	a0,a0,-1736 # 80008608 <syscalls+0x1c8>
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	870080e7          	jalr	-1936(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce0:	24c1                	addiw	s1,s1,16
    80003ce2:	04c92783          	lw	a5,76(s2)
    80003ce6:	04f4f763          	bgeu	s1,a5,80003d34 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cea:	4741                	li	a4,16
    80003cec:	86a6                	mv	a3,s1
    80003cee:	fc040613          	addi	a2,s0,-64
    80003cf2:	4581                	li	a1,0
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	d76080e7          	jalr	-650(ra) # 80003a6c <readi>
    80003cfe:	47c1                	li	a5,16
    80003d00:	fcf518e3          	bne	a0,a5,80003cd0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d04:	fc045783          	lhu	a5,-64(s0)
    80003d08:	dfe1                	beqz	a5,80003ce0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d0a:	fc240593          	addi	a1,s0,-62
    80003d0e:	854e                	mv	a0,s3
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	f6c080e7          	jalr	-148(ra) # 80003c7c <namecmp>
    80003d18:	f561                	bnez	a0,80003ce0 <dirlookup+0x4a>
      if(poff)
    80003d1a:	000a0463          	beqz	s4,80003d22 <dirlookup+0x8c>
        *poff = off;
    80003d1e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d22:	fc045583          	lhu	a1,-64(s0)
    80003d26:	00092503          	lw	a0,0(s2)
    80003d2a:	fffff097          	auipc	ra,0xfffff
    80003d2e:	75a080e7          	jalr	1882(ra) # 80003484 <iget>
    80003d32:	a011                	j	80003d36 <dirlookup+0xa0>
  return 0;
    80003d34:	4501                	li	a0,0
}
    80003d36:	70e2                	ld	ra,56(sp)
    80003d38:	7442                	ld	s0,48(sp)
    80003d3a:	74a2                	ld	s1,40(sp)
    80003d3c:	7902                	ld	s2,32(sp)
    80003d3e:	69e2                	ld	s3,24(sp)
    80003d40:	6a42                	ld	s4,16(sp)
    80003d42:	6121                	addi	sp,sp,64
    80003d44:	8082                	ret

0000000080003d46 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d46:	711d                	addi	sp,sp,-96
    80003d48:	ec86                	sd	ra,88(sp)
    80003d4a:	e8a2                	sd	s0,80(sp)
    80003d4c:	e4a6                	sd	s1,72(sp)
    80003d4e:	e0ca                	sd	s2,64(sp)
    80003d50:	fc4e                	sd	s3,56(sp)
    80003d52:	f852                	sd	s4,48(sp)
    80003d54:	f456                	sd	s5,40(sp)
    80003d56:	f05a                	sd	s6,32(sp)
    80003d58:	ec5e                	sd	s7,24(sp)
    80003d5a:	e862                	sd	s8,16(sp)
    80003d5c:	e466                	sd	s9,8(sp)
    80003d5e:	1080                	addi	s0,sp,96
    80003d60:	84aa                	mv	s1,a0
    80003d62:	8b2e                	mv	s6,a1
    80003d64:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d66:	00054703          	lbu	a4,0(a0)
    80003d6a:	02f00793          	li	a5,47
    80003d6e:	02f70363          	beq	a4,a5,80003d94 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d72:	ffffe097          	auipc	ra,0xffffe
    80003d76:	cd8080e7          	jalr	-808(ra) # 80001a4a <myproc>
    80003d7a:	15053503          	ld	a0,336(a0)
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	9fc080e7          	jalr	-1540(ra) # 8000377a <idup>
    80003d86:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d88:	02f00913          	li	s2,47
  len = path - s;
    80003d8c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d8e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d90:	4c05                	li	s8,1
    80003d92:	a865                	j	80003e4a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d94:	4585                	li	a1,1
    80003d96:	4505                	li	a0,1
    80003d98:	fffff097          	auipc	ra,0xfffff
    80003d9c:	6ec080e7          	jalr	1772(ra) # 80003484 <iget>
    80003da0:	89aa                	mv	s3,a0
    80003da2:	b7dd                	j	80003d88 <namex+0x42>
      iunlockput(ip);
    80003da4:	854e                	mv	a0,s3
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	c74080e7          	jalr	-908(ra) # 80003a1a <iunlockput>
      return 0;
    80003dae:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003db0:	854e                	mv	a0,s3
    80003db2:	60e6                	ld	ra,88(sp)
    80003db4:	6446                	ld	s0,80(sp)
    80003db6:	64a6                	ld	s1,72(sp)
    80003db8:	6906                	ld	s2,64(sp)
    80003dba:	79e2                	ld	s3,56(sp)
    80003dbc:	7a42                	ld	s4,48(sp)
    80003dbe:	7aa2                	ld	s5,40(sp)
    80003dc0:	7b02                	ld	s6,32(sp)
    80003dc2:	6be2                	ld	s7,24(sp)
    80003dc4:	6c42                	ld	s8,16(sp)
    80003dc6:	6ca2                	ld	s9,8(sp)
    80003dc8:	6125                	addi	sp,sp,96
    80003dca:	8082                	ret
      iunlock(ip);
    80003dcc:	854e                	mv	a0,s3
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	aac080e7          	jalr	-1364(ra) # 8000387a <iunlock>
      return ip;
    80003dd6:	bfe9                	j	80003db0 <namex+0x6a>
      iunlockput(ip);
    80003dd8:	854e                	mv	a0,s3
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	c40080e7          	jalr	-960(ra) # 80003a1a <iunlockput>
      return 0;
    80003de2:	89d2                	mv	s3,s4
    80003de4:	b7f1                	j	80003db0 <namex+0x6a>
  len = path - s;
    80003de6:	40b48633          	sub	a2,s1,a1
    80003dea:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dee:	094cd463          	bge	s9,s4,80003e76 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003df2:	4639                	li	a2,14
    80003df4:	8556                	mv	a0,s5
    80003df6:	ffffd097          	auipc	ra,0xffffd
    80003dfa:	fe2080e7          	jalr	-30(ra) # 80000dd8 <memmove>
  while(*path == '/')
    80003dfe:	0004c783          	lbu	a5,0(s1)
    80003e02:	01279763          	bne	a5,s2,80003e10 <namex+0xca>
    path++;
    80003e06:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e08:	0004c783          	lbu	a5,0(s1)
    80003e0c:	ff278de3          	beq	a5,s2,80003e06 <namex+0xc0>
    ilock(ip);
    80003e10:	854e                	mv	a0,s3
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	9a6080e7          	jalr	-1626(ra) # 800037b8 <ilock>
    if(ip->type != T_DIR){
    80003e1a:	04499783          	lh	a5,68(s3)
    80003e1e:	f98793e3          	bne	a5,s8,80003da4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e22:	000b0563          	beqz	s6,80003e2c <namex+0xe6>
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	d3cd                	beqz	a5,80003dcc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e2c:	865e                	mv	a2,s7
    80003e2e:	85d6                	mv	a1,s5
    80003e30:	854e                	mv	a0,s3
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	e64080e7          	jalr	-412(ra) # 80003c96 <dirlookup>
    80003e3a:	8a2a                	mv	s4,a0
    80003e3c:	dd51                	beqz	a0,80003dd8 <namex+0x92>
    iunlockput(ip);
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	bda080e7          	jalr	-1062(ra) # 80003a1a <iunlockput>
    ip = next;
    80003e48:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e4a:	0004c783          	lbu	a5,0(s1)
    80003e4e:	05279763          	bne	a5,s2,80003e9c <namex+0x156>
    path++;
    80003e52:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e54:	0004c783          	lbu	a5,0(s1)
    80003e58:	ff278de3          	beq	a5,s2,80003e52 <namex+0x10c>
  if(*path == 0)
    80003e5c:	c79d                	beqz	a5,80003e8a <namex+0x144>
    path++;
    80003e5e:	85a6                	mv	a1,s1
  len = path - s;
    80003e60:	8a5e                	mv	s4,s7
    80003e62:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e64:	01278963          	beq	a5,s2,80003e76 <namex+0x130>
    80003e68:	dfbd                	beqz	a5,80003de6 <namex+0xa0>
    path++;
    80003e6a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e6c:	0004c783          	lbu	a5,0(s1)
    80003e70:	ff279ce3          	bne	a5,s2,80003e68 <namex+0x122>
    80003e74:	bf8d                	j	80003de6 <namex+0xa0>
    memmove(name, s, len);
    80003e76:	2601                	sext.w	a2,a2
    80003e78:	8556                	mv	a0,s5
    80003e7a:	ffffd097          	auipc	ra,0xffffd
    80003e7e:	f5e080e7          	jalr	-162(ra) # 80000dd8 <memmove>
    name[len] = 0;
    80003e82:	9a56                	add	s4,s4,s5
    80003e84:	000a0023          	sb	zero,0(s4)
    80003e88:	bf9d                	j	80003dfe <namex+0xb8>
  if(nameiparent){
    80003e8a:	f20b03e3          	beqz	s6,80003db0 <namex+0x6a>
    iput(ip);
    80003e8e:	854e                	mv	a0,s3
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	ae2080e7          	jalr	-1310(ra) # 80003972 <iput>
    return 0;
    80003e98:	4981                	li	s3,0
    80003e9a:	bf19                	j	80003db0 <namex+0x6a>
  if(*path == 0)
    80003e9c:	d7fd                	beqz	a5,80003e8a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e9e:	0004c783          	lbu	a5,0(s1)
    80003ea2:	85a6                	mv	a1,s1
    80003ea4:	b7d1                	j	80003e68 <namex+0x122>

0000000080003ea6 <dirlink>:
{
    80003ea6:	7139                	addi	sp,sp,-64
    80003ea8:	fc06                	sd	ra,56(sp)
    80003eaa:	f822                	sd	s0,48(sp)
    80003eac:	f426                	sd	s1,40(sp)
    80003eae:	f04a                	sd	s2,32(sp)
    80003eb0:	ec4e                	sd	s3,24(sp)
    80003eb2:	e852                	sd	s4,16(sp)
    80003eb4:	0080                	addi	s0,sp,64
    80003eb6:	892a                	mv	s2,a0
    80003eb8:	8a2e                	mv	s4,a1
    80003eba:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ebc:	4601                	li	a2,0
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	dd8080e7          	jalr	-552(ra) # 80003c96 <dirlookup>
    80003ec6:	e93d                	bnez	a0,80003f3c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec8:	04c92483          	lw	s1,76(s2)
    80003ecc:	c49d                	beqz	s1,80003efa <dirlink+0x54>
    80003ece:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed0:	4741                	li	a4,16
    80003ed2:	86a6                	mv	a3,s1
    80003ed4:	fc040613          	addi	a2,s0,-64
    80003ed8:	4581                	li	a1,0
    80003eda:	854a                	mv	a0,s2
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	b90080e7          	jalr	-1136(ra) # 80003a6c <readi>
    80003ee4:	47c1                	li	a5,16
    80003ee6:	06f51163          	bne	a0,a5,80003f48 <dirlink+0xa2>
    if(de.inum == 0)
    80003eea:	fc045783          	lhu	a5,-64(s0)
    80003eee:	c791                	beqz	a5,80003efa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef0:	24c1                	addiw	s1,s1,16
    80003ef2:	04c92783          	lw	a5,76(s2)
    80003ef6:	fcf4ede3          	bltu	s1,a5,80003ed0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003efa:	4639                	li	a2,14
    80003efc:	85d2                	mv	a1,s4
    80003efe:	fc240513          	addi	a0,s0,-62
    80003f02:	ffffd097          	auipc	ra,0xffffd
    80003f06:	f8e080e7          	jalr	-114(ra) # 80000e90 <strncpy>
  de.inum = inum;
    80003f0a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0e:	4741                	li	a4,16
    80003f10:	86a6                	mv	a3,s1
    80003f12:	fc040613          	addi	a2,s0,-64
    80003f16:	4581                	li	a1,0
    80003f18:	854a                	mv	a0,s2
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	c48080e7          	jalr	-952(ra) # 80003b62 <writei>
    80003f22:	872a                	mv	a4,a0
    80003f24:	47c1                	li	a5,16
  return 0;
    80003f26:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f28:	02f71863          	bne	a4,a5,80003f58 <dirlink+0xb2>
}
    80003f2c:	70e2                	ld	ra,56(sp)
    80003f2e:	7442                	ld	s0,48(sp)
    80003f30:	74a2                	ld	s1,40(sp)
    80003f32:	7902                	ld	s2,32(sp)
    80003f34:	69e2                	ld	s3,24(sp)
    80003f36:	6a42                	ld	s4,16(sp)
    80003f38:	6121                	addi	sp,sp,64
    80003f3a:	8082                	ret
    iput(ip);
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	a36080e7          	jalr	-1482(ra) # 80003972 <iput>
    return -1;
    80003f44:	557d                	li	a0,-1
    80003f46:	b7dd                	j	80003f2c <dirlink+0x86>
      panic("dirlink read");
    80003f48:	00004517          	auipc	a0,0x4
    80003f4c:	6d050513          	addi	a0,a0,1744 # 80008618 <syscalls+0x1d8>
    80003f50:	ffffc097          	auipc	ra,0xffffc
    80003f54:	5f8080e7          	jalr	1528(ra) # 80000548 <panic>
    panic("dirlink");
    80003f58:	00004517          	auipc	a0,0x4
    80003f5c:	7e050513          	addi	a0,a0,2016 # 80008738 <syscalls+0x2f8>
    80003f60:	ffffc097          	auipc	ra,0xffffc
    80003f64:	5e8080e7          	jalr	1512(ra) # 80000548 <panic>

0000000080003f68 <namei>:

struct inode*
namei(char *path)
{
    80003f68:	1101                	addi	sp,sp,-32
    80003f6a:	ec06                	sd	ra,24(sp)
    80003f6c:	e822                	sd	s0,16(sp)
    80003f6e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f70:	fe040613          	addi	a2,s0,-32
    80003f74:	4581                	li	a1,0
    80003f76:	00000097          	auipc	ra,0x0
    80003f7a:	dd0080e7          	jalr	-560(ra) # 80003d46 <namex>
}
    80003f7e:	60e2                	ld	ra,24(sp)
    80003f80:	6442                	ld	s0,16(sp)
    80003f82:	6105                	addi	sp,sp,32
    80003f84:	8082                	ret

0000000080003f86 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f86:	1141                	addi	sp,sp,-16
    80003f88:	e406                	sd	ra,8(sp)
    80003f8a:	e022                	sd	s0,0(sp)
    80003f8c:	0800                	addi	s0,sp,16
    80003f8e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f90:	4585                	li	a1,1
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	db4080e7          	jalr	-588(ra) # 80003d46 <namex>
}
    80003f9a:	60a2                	ld	ra,8(sp)
    80003f9c:	6402                	ld	s0,0(sp)
    80003f9e:	0141                	addi	sp,sp,16
    80003fa0:	8082                	ret

0000000080003fa2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fa2:	1101                	addi	sp,sp,-32
    80003fa4:	ec06                	sd	ra,24(sp)
    80003fa6:	e822                	sd	s0,16(sp)
    80003fa8:	e426                	sd	s1,8(sp)
    80003faa:	e04a                	sd	s2,0(sp)
    80003fac:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fae:	0001e917          	auipc	s2,0x1e
    80003fb2:	15a90913          	addi	s2,s2,346 # 80022108 <log>
    80003fb6:	01892583          	lw	a1,24(s2)
    80003fba:	02892503          	lw	a0,40(s2)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	ff8080e7          	jalr	-8(ra) # 80002fb6 <bread>
    80003fc6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fc8:	02c92683          	lw	a3,44(s2)
    80003fcc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fce:	02d05763          	blez	a3,80003ffc <write_head+0x5a>
    80003fd2:	0001e797          	auipc	a5,0x1e
    80003fd6:	16678793          	addi	a5,a5,358 # 80022138 <log+0x30>
    80003fda:	05c50713          	addi	a4,a0,92
    80003fde:	36fd                	addiw	a3,a3,-1
    80003fe0:	1682                	slli	a3,a3,0x20
    80003fe2:	9281                	srli	a3,a3,0x20
    80003fe4:	068a                	slli	a3,a3,0x2
    80003fe6:	0001e617          	auipc	a2,0x1e
    80003fea:	15660613          	addi	a2,a2,342 # 8002213c <log+0x34>
    80003fee:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ff0:	4390                	lw	a2,0(a5)
    80003ff2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff4:	0791                	addi	a5,a5,4
    80003ff6:	0711                	addi	a4,a4,4
    80003ff8:	fed79ce3          	bne	a5,a3,80003ff0 <write_head+0x4e>
  }
  bwrite(buf);
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	fffff097          	auipc	ra,0xfffff
    80004002:	0aa080e7          	jalr	170(ra) # 800030a8 <bwrite>
  brelse(buf);
    80004006:	8526                	mv	a0,s1
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	0de080e7          	jalr	222(ra) # 800030e6 <brelse>
}
    80004010:	60e2                	ld	ra,24(sp)
    80004012:	6442                	ld	s0,16(sp)
    80004014:	64a2                	ld	s1,8(sp)
    80004016:	6902                	ld	s2,0(sp)
    80004018:	6105                	addi	sp,sp,32
    8000401a:	8082                	ret

000000008000401c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401c:	0001e797          	auipc	a5,0x1e
    80004020:	1187a783          	lw	a5,280(a5) # 80022134 <log+0x2c>
    80004024:	0af05663          	blez	a5,800040d0 <install_trans+0xb4>
{
    80004028:	7139                	addi	sp,sp,-64
    8000402a:	fc06                	sd	ra,56(sp)
    8000402c:	f822                	sd	s0,48(sp)
    8000402e:	f426                	sd	s1,40(sp)
    80004030:	f04a                	sd	s2,32(sp)
    80004032:	ec4e                	sd	s3,24(sp)
    80004034:	e852                	sd	s4,16(sp)
    80004036:	e456                	sd	s5,8(sp)
    80004038:	0080                	addi	s0,sp,64
    8000403a:	0001ea97          	auipc	s5,0x1e
    8000403e:	0fea8a93          	addi	s5,s5,254 # 80022138 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004042:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004044:	0001e997          	auipc	s3,0x1e
    80004048:	0c498993          	addi	s3,s3,196 # 80022108 <log>
    8000404c:	0189a583          	lw	a1,24(s3)
    80004050:	014585bb          	addw	a1,a1,s4
    80004054:	2585                	addiw	a1,a1,1
    80004056:	0289a503          	lw	a0,40(s3)
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	f5c080e7          	jalr	-164(ra) # 80002fb6 <bread>
    80004062:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004064:	000aa583          	lw	a1,0(s5)
    80004068:	0289a503          	lw	a0,40(s3)
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	f4a080e7          	jalr	-182(ra) # 80002fb6 <bread>
    80004074:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004076:	40000613          	li	a2,1024
    8000407a:	05890593          	addi	a1,s2,88
    8000407e:	05850513          	addi	a0,a0,88
    80004082:	ffffd097          	auipc	ra,0xffffd
    80004086:	d56080e7          	jalr	-682(ra) # 80000dd8 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000408a:	8526                	mv	a0,s1
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	01c080e7          	jalr	28(ra) # 800030a8 <bwrite>
    bunpin(dbuf);
    80004094:	8526                	mv	a0,s1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	12a080e7          	jalr	298(ra) # 800031c0 <bunpin>
    brelse(lbuf);
    8000409e:	854a                	mv	a0,s2
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	046080e7          	jalr	70(ra) # 800030e6 <brelse>
    brelse(dbuf);
    800040a8:	8526                	mv	a0,s1
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	03c080e7          	jalr	60(ra) # 800030e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b2:	2a05                	addiw	s4,s4,1
    800040b4:	0a91                	addi	s5,s5,4
    800040b6:	02c9a783          	lw	a5,44(s3)
    800040ba:	f8fa49e3          	blt	s4,a5,8000404c <install_trans+0x30>
}
    800040be:	70e2                	ld	ra,56(sp)
    800040c0:	7442                	ld	s0,48(sp)
    800040c2:	74a2                	ld	s1,40(sp)
    800040c4:	7902                	ld	s2,32(sp)
    800040c6:	69e2                	ld	s3,24(sp)
    800040c8:	6a42                	ld	s4,16(sp)
    800040ca:	6aa2                	ld	s5,8(sp)
    800040cc:	6121                	addi	sp,sp,64
    800040ce:	8082                	ret
    800040d0:	8082                	ret

00000000800040d2 <initlog>:
{
    800040d2:	7179                	addi	sp,sp,-48
    800040d4:	f406                	sd	ra,40(sp)
    800040d6:	f022                	sd	s0,32(sp)
    800040d8:	ec26                	sd	s1,24(sp)
    800040da:	e84a                	sd	s2,16(sp)
    800040dc:	e44e                	sd	s3,8(sp)
    800040de:	1800                	addi	s0,sp,48
    800040e0:	892a                	mv	s2,a0
    800040e2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e4:	0001e497          	auipc	s1,0x1e
    800040e8:	02448493          	addi	s1,s1,36 # 80022108 <log>
    800040ec:	00004597          	auipc	a1,0x4
    800040f0:	53c58593          	addi	a1,a1,1340 # 80008628 <syscalls+0x1e8>
    800040f4:	8526                	mv	a0,s1
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	af6080e7          	jalr	-1290(ra) # 80000bec <initlock>
  log.start = sb->logstart;
    800040fe:	0149a583          	lw	a1,20(s3)
    80004102:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004104:	0109a783          	lw	a5,16(s3)
    80004108:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000410a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000410e:	854a                	mv	a0,s2
    80004110:	fffff097          	auipc	ra,0xfffff
    80004114:	ea6080e7          	jalr	-346(ra) # 80002fb6 <bread>
  log.lh.n = lh->n;
    80004118:	4d3c                	lw	a5,88(a0)
    8000411a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000411c:	02f05563          	blez	a5,80004146 <initlog+0x74>
    80004120:	05c50713          	addi	a4,a0,92
    80004124:	0001e697          	auipc	a3,0x1e
    80004128:	01468693          	addi	a3,a3,20 # 80022138 <log+0x30>
    8000412c:	37fd                	addiw	a5,a5,-1
    8000412e:	1782                	slli	a5,a5,0x20
    80004130:	9381                	srli	a5,a5,0x20
    80004132:	078a                	slli	a5,a5,0x2
    80004134:	06050613          	addi	a2,a0,96
    80004138:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000413a:	4310                	lw	a2,0(a4)
    8000413c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000413e:	0711                	addi	a4,a4,4
    80004140:	0691                	addi	a3,a3,4
    80004142:	fef71ce3          	bne	a4,a5,8000413a <initlog+0x68>
  brelse(buf);
    80004146:	fffff097          	auipc	ra,0xfffff
    8000414a:	fa0080e7          	jalr	-96(ra) # 800030e6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	ece080e7          	jalr	-306(ra) # 8000401c <install_trans>
  log.lh.n = 0;
    80004156:	0001e797          	auipc	a5,0x1e
    8000415a:	fc07af23          	sw	zero,-34(a5) # 80022134 <log+0x2c>
  write_head(); // clear the log
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	e44080e7          	jalr	-444(ra) # 80003fa2 <write_head>
}
    80004166:	70a2                	ld	ra,40(sp)
    80004168:	7402                	ld	s0,32(sp)
    8000416a:	64e2                	ld	s1,24(sp)
    8000416c:	6942                	ld	s2,16(sp)
    8000416e:	69a2                	ld	s3,8(sp)
    80004170:	6145                	addi	sp,sp,48
    80004172:	8082                	ret

0000000080004174 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004174:	1101                	addi	sp,sp,-32
    80004176:	ec06                	sd	ra,24(sp)
    80004178:	e822                	sd	s0,16(sp)
    8000417a:	e426                	sd	s1,8(sp)
    8000417c:	e04a                	sd	s2,0(sp)
    8000417e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004180:	0001e517          	auipc	a0,0x1e
    80004184:	f8850513          	addi	a0,a0,-120 # 80022108 <log>
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	af4080e7          	jalr	-1292(ra) # 80000c7c <acquire>
  while(1){
    if(log.committing){
    80004190:	0001e497          	auipc	s1,0x1e
    80004194:	f7848493          	addi	s1,s1,-136 # 80022108 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004198:	4979                	li	s2,30
    8000419a:	a039                	j	800041a8 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000419c:	85a6                	mv	a1,s1
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	110080e7          	jalr	272(ra) # 800022b0 <sleep>
    if(log.committing){
    800041a8:	50dc                	lw	a5,36(s1)
    800041aa:	fbed                	bnez	a5,8000419c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ac:	509c                	lw	a5,32(s1)
    800041ae:	0017871b          	addiw	a4,a5,1
    800041b2:	0007069b          	sext.w	a3,a4
    800041b6:	0027179b          	slliw	a5,a4,0x2
    800041ba:	9fb9                	addw	a5,a5,a4
    800041bc:	0017979b          	slliw	a5,a5,0x1
    800041c0:	54d8                	lw	a4,44(s1)
    800041c2:	9fb9                	addw	a5,a5,a4
    800041c4:	00f95963          	bge	s2,a5,800041d6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041c8:	85a6                	mv	a1,s1
    800041ca:	8526                	mv	a0,s1
    800041cc:	ffffe097          	auipc	ra,0xffffe
    800041d0:	0e4080e7          	jalr	228(ra) # 800022b0 <sleep>
    800041d4:	bfd1                	j	800041a8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041d6:	0001e517          	auipc	a0,0x1e
    800041da:	f3250513          	addi	a0,a0,-206 # 80022108 <log>
    800041de:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	b50080e7          	jalr	-1200(ra) # 80000d30 <release>
      break;
    }
  }
}
    800041e8:	60e2                	ld	ra,24(sp)
    800041ea:	6442                	ld	s0,16(sp)
    800041ec:	64a2                	ld	s1,8(sp)
    800041ee:	6902                	ld	s2,0(sp)
    800041f0:	6105                	addi	sp,sp,32
    800041f2:	8082                	ret

00000000800041f4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f4:	7139                	addi	sp,sp,-64
    800041f6:	fc06                	sd	ra,56(sp)
    800041f8:	f822                	sd	s0,48(sp)
    800041fa:	f426                	sd	s1,40(sp)
    800041fc:	f04a                	sd	s2,32(sp)
    800041fe:	ec4e                	sd	s3,24(sp)
    80004200:	e852                	sd	s4,16(sp)
    80004202:	e456                	sd	s5,8(sp)
    80004204:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004206:	0001e497          	auipc	s1,0x1e
    8000420a:	f0248493          	addi	s1,s1,-254 # 80022108 <log>
    8000420e:	8526                	mv	a0,s1
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	a6c080e7          	jalr	-1428(ra) # 80000c7c <acquire>
  log.outstanding -= 1;
    80004218:	509c                	lw	a5,32(s1)
    8000421a:	37fd                	addiw	a5,a5,-1
    8000421c:	0007891b          	sext.w	s2,a5
    80004220:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004222:	50dc                	lw	a5,36(s1)
    80004224:	efb9                	bnez	a5,80004282 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004226:	06091663          	bnez	s2,80004292 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000422a:	0001e497          	auipc	s1,0x1e
    8000422e:	ede48493          	addi	s1,s1,-290 # 80022108 <log>
    80004232:	4785                	li	a5,1
    80004234:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004236:	8526                	mv	a0,s1
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	af8080e7          	jalr	-1288(ra) # 80000d30 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004240:	54dc                	lw	a5,44(s1)
    80004242:	06f04763          	bgtz	a5,800042b0 <end_op+0xbc>
    acquire(&log.lock);
    80004246:	0001e497          	auipc	s1,0x1e
    8000424a:	ec248493          	addi	s1,s1,-318 # 80022108 <log>
    8000424e:	8526                	mv	a0,s1
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	a2c080e7          	jalr	-1492(ra) # 80000c7c <acquire>
    log.committing = 0;
    80004258:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000425c:	8526                	mv	a0,s1
    8000425e:	ffffe097          	auipc	ra,0xffffe
    80004262:	1d8080e7          	jalr	472(ra) # 80002436 <wakeup>
    release(&log.lock);
    80004266:	8526                	mv	a0,s1
    80004268:	ffffd097          	auipc	ra,0xffffd
    8000426c:	ac8080e7          	jalr	-1336(ra) # 80000d30 <release>
}
    80004270:	70e2                	ld	ra,56(sp)
    80004272:	7442                	ld	s0,48(sp)
    80004274:	74a2                	ld	s1,40(sp)
    80004276:	7902                	ld	s2,32(sp)
    80004278:	69e2                	ld	s3,24(sp)
    8000427a:	6a42                	ld	s4,16(sp)
    8000427c:	6aa2                	ld	s5,8(sp)
    8000427e:	6121                	addi	sp,sp,64
    80004280:	8082                	ret
    panic("log.committing");
    80004282:	00004517          	auipc	a0,0x4
    80004286:	3ae50513          	addi	a0,a0,942 # 80008630 <syscalls+0x1f0>
    8000428a:	ffffc097          	auipc	ra,0xffffc
    8000428e:	2be080e7          	jalr	702(ra) # 80000548 <panic>
    wakeup(&log);
    80004292:	0001e497          	auipc	s1,0x1e
    80004296:	e7648493          	addi	s1,s1,-394 # 80022108 <log>
    8000429a:	8526                	mv	a0,s1
    8000429c:	ffffe097          	auipc	ra,0xffffe
    800042a0:	19a080e7          	jalr	410(ra) # 80002436 <wakeup>
  release(&log.lock);
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	a8a080e7          	jalr	-1398(ra) # 80000d30 <release>
  if(do_commit){
    800042ae:	b7c9                	j	80004270 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b0:	0001ea97          	auipc	s5,0x1e
    800042b4:	e88a8a93          	addi	s5,s5,-376 # 80022138 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042b8:	0001ea17          	auipc	s4,0x1e
    800042bc:	e50a0a13          	addi	s4,s4,-432 # 80022108 <log>
    800042c0:	018a2583          	lw	a1,24(s4)
    800042c4:	012585bb          	addw	a1,a1,s2
    800042c8:	2585                	addiw	a1,a1,1
    800042ca:	028a2503          	lw	a0,40(s4)
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	ce8080e7          	jalr	-792(ra) # 80002fb6 <bread>
    800042d6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042d8:	000aa583          	lw	a1,0(s5)
    800042dc:	028a2503          	lw	a0,40(s4)
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	cd6080e7          	jalr	-810(ra) # 80002fb6 <bread>
    800042e8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042ea:	40000613          	li	a2,1024
    800042ee:	05850593          	addi	a1,a0,88
    800042f2:	05848513          	addi	a0,s1,88
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	ae2080e7          	jalr	-1310(ra) # 80000dd8 <memmove>
    bwrite(to);  // write the log
    800042fe:	8526                	mv	a0,s1
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	da8080e7          	jalr	-600(ra) # 800030a8 <bwrite>
    brelse(from);
    80004308:	854e                	mv	a0,s3
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	ddc080e7          	jalr	-548(ra) # 800030e6 <brelse>
    brelse(to);
    80004312:	8526                	mv	a0,s1
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	dd2080e7          	jalr	-558(ra) # 800030e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431c:	2905                	addiw	s2,s2,1
    8000431e:	0a91                	addi	s5,s5,4
    80004320:	02ca2783          	lw	a5,44(s4)
    80004324:	f8f94ee3          	blt	s2,a5,800042c0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	c7a080e7          	jalr	-902(ra) # 80003fa2 <write_head>
    install_trans(); // Now install writes to home locations
    80004330:	00000097          	auipc	ra,0x0
    80004334:	cec080e7          	jalr	-788(ra) # 8000401c <install_trans>
    log.lh.n = 0;
    80004338:	0001e797          	auipc	a5,0x1e
    8000433c:	de07ae23          	sw	zero,-516(a5) # 80022134 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004340:	00000097          	auipc	ra,0x0
    80004344:	c62080e7          	jalr	-926(ra) # 80003fa2 <write_head>
    80004348:	bdfd                	j	80004246 <end_op+0x52>

000000008000434a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000434a:	1101                	addi	sp,sp,-32
    8000434c:	ec06                	sd	ra,24(sp)
    8000434e:	e822                	sd	s0,16(sp)
    80004350:	e426                	sd	s1,8(sp)
    80004352:	e04a                	sd	s2,0(sp)
    80004354:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004356:	0001e717          	auipc	a4,0x1e
    8000435a:	dde72703          	lw	a4,-546(a4) # 80022134 <log+0x2c>
    8000435e:	47f5                	li	a5,29
    80004360:	08e7c063          	blt	a5,a4,800043e0 <log_write+0x96>
    80004364:	84aa                	mv	s1,a0
    80004366:	0001e797          	auipc	a5,0x1e
    8000436a:	dbe7a783          	lw	a5,-578(a5) # 80022124 <log+0x1c>
    8000436e:	37fd                	addiw	a5,a5,-1
    80004370:	06f75863          	bge	a4,a5,800043e0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004374:	0001e797          	auipc	a5,0x1e
    80004378:	db47a783          	lw	a5,-588(a5) # 80022128 <log+0x20>
    8000437c:	06f05a63          	blez	a5,800043f0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004380:	0001e917          	auipc	s2,0x1e
    80004384:	d8890913          	addi	s2,s2,-632 # 80022108 <log>
    80004388:	854a                	mv	a0,s2
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	8f2080e7          	jalr	-1806(ra) # 80000c7c <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004392:	02c92603          	lw	a2,44(s2)
    80004396:	06c05563          	blez	a2,80004400 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000439a:	44cc                	lw	a1,12(s1)
    8000439c:	0001e717          	auipc	a4,0x1e
    800043a0:	d9c70713          	addi	a4,a4,-612 # 80022138 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043a6:	4314                	lw	a3,0(a4)
    800043a8:	04b68d63          	beq	a3,a1,80004402 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043ac:	2785                	addiw	a5,a5,1
    800043ae:	0711                	addi	a4,a4,4
    800043b0:	fec79be3          	bne	a5,a2,800043a6 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043b4:	0621                	addi	a2,a2,8
    800043b6:	060a                	slli	a2,a2,0x2
    800043b8:	0001e797          	auipc	a5,0x1e
    800043bc:	d5078793          	addi	a5,a5,-688 # 80022108 <log>
    800043c0:	963e                	add	a2,a2,a5
    800043c2:	44dc                	lw	a5,12(s1)
    800043c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	dbc080e7          	jalr	-580(ra) # 80003184 <bpin>
    log.lh.n++;
    800043d0:	0001e717          	auipc	a4,0x1e
    800043d4:	d3870713          	addi	a4,a4,-712 # 80022108 <log>
    800043d8:	575c                	lw	a5,44(a4)
    800043da:	2785                	addiw	a5,a5,1
    800043dc:	d75c                	sw	a5,44(a4)
    800043de:	a83d                	j	8000441c <log_write+0xd2>
    panic("too big a transaction");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	26050513          	addi	a0,a0,608 # 80008640 <syscalls+0x200>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	160080e7          	jalr	352(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	26850513          	addi	a0,a0,616 # 80008658 <syscalls+0x218>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	150080e7          	jalr	336(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004400:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004402:	00878713          	addi	a4,a5,8
    80004406:	00271693          	slli	a3,a4,0x2
    8000440a:	0001e717          	auipc	a4,0x1e
    8000440e:	cfe70713          	addi	a4,a4,-770 # 80022108 <log>
    80004412:	9736                	add	a4,a4,a3
    80004414:	44d4                	lw	a3,12(s1)
    80004416:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004418:	faf607e3          	beq	a2,a5,800043c6 <log_write+0x7c>
  }
  release(&log.lock);
    8000441c:	0001e517          	auipc	a0,0x1e
    80004420:	cec50513          	addi	a0,a0,-788 # 80022108 <log>
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	90c080e7          	jalr	-1780(ra) # 80000d30 <release>
}
    8000442c:	60e2                	ld	ra,24(sp)
    8000442e:	6442                	ld	s0,16(sp)
    80004430:	64a2                	ld	s1,8(sp)
    80004432:	6902                	ld	s2,0(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004438:	1101                	addi	sp,sp,-32
    8000443a:	ec06                	sd	ra,24(sp)
    8000443c:	e822                	sd	s0,16(sp)
    8000443e:	e426                	sd	s1,8(sp)
    80004440:	e04a                	sd	s2,0(sp)
    80004442:	1000                	addi	s0,sp,32
    80004444:	84aa                	mv	s1,a0
    80004446:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004448:	00004597          	auipc	a1,0x4
    8000444c:	23058593          	addi	a1,a1,560 # 80008678 <syscalls+0x238>
    80004450:	0521                	addi	a0,a0,8
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	79a080e7          	jalr	1946(ra) # 80000bec <initlock>
  lk->name = name;
    8000445a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000445e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004462:	0204a423          	sw	zero,40(s1)
}
    80004466:	60e2                	ld	ra,24(sp)
    80004468:	6442                	ld	s0,16(sp)
    8000446a:	64a2                	ld	s1,8(sp)
    8000446c:	6902                	ld	s2,0(sp)
    8000446e:	6105                	addi	sp,sp,32
    80004470:	8082                	ret

0000000080004472 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004472:	1101                	addi	sp,sp,-32
    80004474:	ec06                	sd	ra,24(sp)
    80004476:	e822                	sd	s0,16(sp)
    80004478:	e426                	sd	s1,8(sp)
    8000447a:	e04a                	sd	s2,0(sp)
    8000447c:	1000                	addi	s0,sp,32
    8000447e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004480:	00850913          	addi	s2,a0,8
    80004484:	854a                	mv	a0,s2
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	7f6080e7          	jalr	2038(ra) # 80000c7c <acquire>
  while (lk->locked) {
    8000448e:	409c                	lw	a5,0(s1)
    80004490:	cb89                	beqz	a5,800044a2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004492:	85ca                	mv	a1,s2
    80004494:	8526                	mv	a0,s1
    80004496:	ffffe097          	auipc	ra,0xffffe
    8000449a:	e1a080e7          	jalr	-486(ra) # 800022b0 <sleep>
  while (lk->locked) {
    8000449e:	409c                	lw	a5,0(s1)
    800044a0:	fbed                	bnez	a5,80004492 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044a2:	4785                	li	a5,1
    800044a4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044a6:	ffffd097          	auipc	ra,0xffffd
    800044aa:	5a4080e7          	jalr	1444(ra) # 80001a4a <myproc>
    800044ae:	5d1c                	lw	a5,56(a0)
    800044b0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffd097          	auipc	ra,0xffffd
    800044b8:	87c080e7          	jalr	-1924(ra) # 80000d30 <release>
}
    800044bc:	60e2                	ld	ra,24(sp)
    800044be:	6442                	ld	s0,16(sp)
    800044c0:	64a2                	ld	s1,8(sp)
    800044c2:	6902                	ld	s2,0(sp)
    800044c4:	6105                	addi	sp,sp,32
    800044c6:	8082                	ret

00000000800044c8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044c8:	1101                	addi	sp,sp,-32
    800044ca:	ec06                	sd	ra,24(sp)
    800044cc:	e822                	sd	s0,16(sp)
    800044ce:	e426                	sd	s1,8(sp)
    800044d0:	e04a                	sd	s2,0(sp)
    800044d2:	1000                	addi	s0,sp,32
    800044d4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044d6:	00850913          	addi	s2,a0,8
    800044da:	854a                	mv	a0,s2
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	7a0080e7          	jalr	1952(ra) # 80000c7c <acquire>
  lk->locked = 0;
    800044e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ec:	8526                	mv	a0,s1
    800044ee:	ffffe097          	auipc	ra,0xffffe
    800044f2:	f48080e7          	jalr	-184(ra) # 80002436 <wakeup>
  release(&lk->lk);
    800044f6:	854a                	mv	a0,s2
    800044f8:	ffffd097          	auipc	ra,0xffffd
    800044fc:	838080e7          	jalr	-1992(ra) # 80000d30 <release>
}
    80004500:	60e2                	ld	ra,24(sp)
    80004502:	6442                	ld	s0,16(sp)
    80004504:	64a2                	ld	s1,8(sp)
    80004506:	6902                	ld	s2,0(sp)
    80004508:	6105                	addi	sp,sp,32
    8000450a:	8082                	ret

000000008000450c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000450c:	7179                	addi	sp,sp,-48
    8000450e:	f406                	sd	ra,40(sp)
    80004510:	f022                	sd	s0,32(sp)
    80004512:	ec26                	sd	s1,24(sp)
    80004514:	e84a                	sd	s2,16(sp)
    80004516:	e44e                	sd	s3,8(sp)
    80004518:	1800                	addi	s0,sp,48
    8000451a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000451c:	00850913          	addi	s2,a0,8
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	75a080e7          	jalr	1882(ra) # 80000c7c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452a:	409c                	lw	a5,0(s1)
    8000452c:	ef99                	bnez	a5,8000454a <holdingsleep+0x3e>
    8000452e:	4481                	li	s1,0
  release(&lk->lk);
    80004530:	854a                	mv	a0,s2
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	7fe080e7          	jalr	2046(ra) # 80000d30 <release>
  return r;
}
    8000453a:	8526                	mv	a0,s1
    8000453c:	70a2                	ld	ra,40(sp)
    8000453e:	7402                	ld	s0,32(sp)
    80004540:	64e2                	ld	s1,24(sp)
    80004542:	6942                	ld	s2,16(sp)
    80004544:	69a2                	ld	s3,8(sp)
    80004546:	6145                	addi	sp,sp,48
    80004548:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000454a:	0284a983          	lw	s3,40(s1)
    8000454e:	ffffd097          	auipc	ra,0xffffd
    80004552:	4fc080e7          	jalr	1276(ra) # 80001a4a <myproc>
    80004556:	5d04                	lw	s1,56(a0)
    80004558:	413484b3          	sub	s1,s1,s3
    8000455c:	0014b493          	seqz	s1,s1
    80004560:	bfc1                	j	80004530 <holdingsleep+0x24>

0000000080004562 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004562:	1141                	addi	sp,sp,-16
    80004564:	e406                	sd	ra,8(sp)
    80004566:	e022                	sd	s0,0(sp)
    80004568:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000456a:	00004597          	auipc	a1,0x4
    8000456e:	11e58593          	addi	a1,a1,286 # 80008688 <syscalls+0x248>
    80004572:	0001e517          	auipc	a0,0x1e
    80004576:	cde50513          	addi	a0,a0,-802 # 80022250 <ftable>
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	672080e7          	jalr	1650(ra) # 80000bec <initlock>
}
    80004582:	60a2                	ld	ra,8(sp)
    80004584:	6402                	ld	s0,0(sp)
    80004586:	0141                	addi	sp,sp,16
    80004588:	8082                	ret

000000008000458a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000458a:	1101                	addi	sp,sp,-32
    8000458c:	ec06                	sd	ra,24(sp)
    8000458e:	e822                	sd	s0,16(sp)
    80004590:	e426                	sd	s1,8(sp)
    80004592:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004594:	0001e517          	auipc	a0,0x1e
    80004598:	cbc50513          	addi	a0,a0,-836 # 80022250 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	6e0080e7          	jalr	1760(ra) # 80000c7c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a4:	0001e497          	auipc	s1,0x1e
    800045a8:	cc448493          	addi	s1,s1,-828 # 80022268 <ftable+0x18>
    800045ac:	0001f717          	auipc	a4,0x1f
    800045b0:	c5c70713          	addi	a4,a4,-932 # 80023208 <ftable+0xfb8>
    if(f->ref == 0){
    800045b4:	40dc                	lw	a5,4(s1)
    800045b6:	cf99                	beqz	a5,800045d4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b8:	02848493          	addi	s1,s1,40
    800045bc:	fee49ce3          	bne	s1,a4,800045b4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045c0:	0001e517          	auipc	a0,0x1e
    800045c4:	c9050513          	addi	a0,a0,-880 # 80022250 <ftable>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	768080e7          	jalr	1896(ra) # 80000d30 <release>
  return 0;
    800045d0:	4481                	li	s1,0
    800045d2:	a819                	j	800045e8 <filealloc+0x5e>
      f->ref = 1;
    800045d4:	4785                	li	a5,1
    800045d6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045d8:	0001e517          	auipc	a0,0x1e
    800045dc:	c7850513          	addi	a0,a0,-904 # 80022250 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	750080e7          	jalr	1872(ra) # 80000d30 <release>
}
    800045e8:	8526                	mv	a0,s1
    800045ea:	60e2                	ld	ra,24(sp)
    800045ec:	6442                	ld	s0,16(sp)
    800045ee:	64a2                	ld	s1,8(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret

00000000800045f4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f4:	1101                	addi	sp,sp,-32
    800045f6:	ec06                	sd	ra,24(sp)
    800045f8:	e822                	sd	s0,16(sp)
    800045fa:	e426                	sd	s1,8(sp)
    800045fc:	1000                	addi	s0,sp,32
    800045fe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004600:	0001e517          	auipc	a0,0x1e
    80004604:	c5050513          	addi	a0,a0,-944 # 80022250 <ftable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	674080e7          	jalr	1652(ra) # 80000c7c <acquire>
  if(f->ref < 1)
    80004610:	40dc                	lw	a5,4(s1)
    80004612:	02f05263          	blez	a5,80004636 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004616:	2785                	addiw	a5,a5,1
    80004618:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000461a:	0001e517          	auipc	a0,0x1e
    8000461e:	c3650513          	addi	a0,a0,-970 # 80022250 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	70e080e7          	jalr	1806(ra) # 80000d30 <release>
  return f;
}
    8000462a:	8526                	mv	a0,s1
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6105                	addi	sp,sp,32
    80004634:	8082                	ret
    panic("filedup");
    80004636:	00004517          	auipc	a0,0x4
    8000463a:	05a50513          	addi	a0,a0,90 # 80008690 <syscalls+0x250>
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	f0a080e7          	jalr	-246(ra) # 80000548 <panic>

0000000080004646 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004646:	7139                	addi	sp,sp,-64
    80004648:	fc06                	sd	ra,56(sp)
    8000464a:	f822                	sd	s0,48(sp)
    8000464c:	f426                	sd	s1,40(sp)
    8000464e:	f04a                	sd	s2,32(sp)
    80004650:	ec4e                	sd	s3,24(sp)
    80004652:	e852                	sd	s4,16(sp)
    80004654:	e456                	sd	s5,8(sp)
    80004656:	0080                	addi	s0,sp,64
    80004658:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000465a:	0001e517          	auipc	a0,0x1e
    8000465e:	bf650513          	addi	a0,a0,-1034 # 80022250 <ftable>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	61a080e7          	jalr	1562(ra) # 80000c7c <acquire>
  if(f->ref < 1)
    8000466a:	40dc                	lw	a5,4(s1)
    8000466c:	06f05163          	blez	a5,800046ce <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004670:	37fd                	addiw	a5,a5,-1
    80004672:	0007871b          	sext.w	a4,a5
    80004676:	c0dc                	sw	a5,4(s1)
    80004678:	06e04363          	bgtz	a4,800046de <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000467c:	0004a903          	lw	s2,0(s1)
    80004680:	0094ca83          	lbu	s5,9(s1)
    80004684:	0104ba03          	ld	s4,16(s1)
    80004688:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000468c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004690:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004694:	0001e517          	auipc	a0,0x1e
    80004698:	bbc50513          	addi	a0,a0,-1092 # 80022250 <ftable>
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	694080e7          	jalr	1684(ra) # 80000d30 <release>

  if(ff.type == FD_PIPE){
    800046a4:	4785                	li	a5,1
    800046a6:	04f90d63          	beq	s2,a5,80004700 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046aa:	3979                	addiw	s2,s2,-2
    800046ac:	4785                	li	a5,1
    800046ae:	0527e063          	bltu	a5,s2,800046ee <fileclose+0xa8>
    begin_op();
    800046b2:	00000097          	auipc	ra,0x0
    800046b6:	ac2080e7          	jalr	-1342(ra) # 80004174 <begin_op>
    iput(ff.ip);
    800046ba:	854e                	mv	a0,s3
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	2b6080e7          	jalr	694(ra) # 80003972 <iput>
    end_op();
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	b30080e7          	jalr	-1232(ra) # 800041f4 <end_op>
    800046cc:	a00d                	j	800046ee <fileclose+0xa8>
    panic("fileclose");
    800046ce:	00004517          	auipc	a0,0x4
    800046d2:	fca50513          	addi	a0,a0,-54 # 80008698 <syscalls+0x258>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	e72080e7          	jalr	-398(ra) # 80000548 <panic>
    release(&ftable.lock);
    800046de:	0001e517          	auipc	a0,0x1e
    800046e2:	b7250513          	addi	a0,a0,-1166 # 80022250 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	64a080e7          	jalr	1610(ra) # 80000d30 <release>
  }
}
    800046ee:	70e2                	ld	ra,56(sp)
    800046f0:	7442                	ld	s0,48(sp)
    800046f2:	74a2                	ld	s1,40(sp)
    800046f4:	7902                	ld	s2,32(sp)
    800046f6:	69e2                	ld	s3,24(sp)
    800046f8:	6a42                	ld	s4,16(sp)
    800046fa:	6aa2                	ld	s5,8(sp)
    800046fc:	6121                	addi	sp,sp,64
    800046fe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004700:	85d6                	mv	a1,s5
    80004702:	8552                	mv	a0,s4
    80004704:	00000097          	auipc	ra,0x0
    80004708:	372080e7          	jalr	882(ra) # 80004a76 <pipeclose>
    8000470c:	b7cd                	j	800046ee <fileclose+0xa8>

000000008000470e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000470e:	715d                	addi	sp,sp,-80
    80004710:	e486                	sd	ra,72(sp)
    80004712:	e0a2                	sd	s0,64(sp)
    80004714:	fc26                	sd	s1,56(sp)
    80004716:	f84a                	sd	s2,48(sp)
    80004718:	f44e                	sd	s3,40(sp)
    8000471a:	0880                	addi	s0,sp,80
    8000471c:	84aa                	mv	s1,a0
    8000471e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004720:	ffffd097          	auipc	ra,0xffffd
    80004724:	32a080e7          	jalr	810(ra) # 80001a4a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004728:	409c                	lw	a5,0(s1)
    8000472a:	37f9                	addiw	a5,a5,-2
    8000472c:	4705                	li	a4,1
    8000472e:	04f76763          	bltu	a4,a5,8000477c <filestat+0x6e>
    80004732:	892a                	mv	s2,a0
    ilock(f->ip);
    80004734:	6c88                	ld	a0,24(s1)
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	082080e7          	jalr	130(ra) # 800037b8 <ilock>
    stati(f->ip, &st);
    8000473e:	fb840593          	addi	a1,s0,-72
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	2fe080e7          	jalr	766(ra) # 80003a42 <stati>
    iunlock(f->ip);
    8000474c:	6c88                	ld	a0,24(s1)
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	12c080e7          	jalr	300(ra) # 8000387a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004756:	46e1                	li	a3,24
    80004758:	fb840613          	addi	a2,s0,-72
    8000475c:	85ce                	mv	a1,s3
    8000475e:	05093503          	ld	a0,80(s2)
    80004762:	ffffd097          	auipc	ra,0xffffd
    80004766:	fdc080e7          	jalr	-36(ra) # 8000173e <copyout>
    8000476a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000476e:	60a6                	ld	ra,72(sp)
    80004770:	6406                	ld	s0,64(sp)
    80004772:	74e2                	ld	s1,56(sp)
    80004774:	7942                	ld	s2,48(sp)
    80004776:	79a2                	ld	s3,40(sp)
    80004778:	6161                	addi	sp,sp,80
    8000477a:	8082                	ret
  return -1;
    8000477c:	557d                	li	a0,-1
    8000477e:	bfc5                	j	8000476e <filestat+0x60>

0000000080004780 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004780:	7179                	addi	sp,sp,-48
    80004782:	f406                	sd	ra,40(sp)
    80004784:	f022                	sd	s0,32(sp)
    80004786:	ec26                	sd	s1,24(sp)
    80004788:	e84a                	sd	s2,16(sp)
    8000478a:	e44e                	sd	s3,8(sp)
    8000478c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000478e:	00854783          	lbu	a5,8(a0)
    80004792:	c3d5                	beqz	a5,80004836 <fileread+0xb6>
    80004794:	84aa                	mv	s1,a0
    80004796:	89ae                	mv	s3,a1
    80004798:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479a:	411c                	lw	a5,0(a0)
    8000479c:	4705                	li	a4,1
    8000479e:	04e78963          	beq	a5,a4,800047f0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a2:	470d                	li	a4,3
    800047a4:	04e78d63          	beq	a5,a4,800047fe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047a8:	4709                	li	a4,2
    800047aa:	06e79e63          	bne	a5,a4,80004826 <fileread+0xa6>
    ilock(f->ip);
    800047ae:	6d08                	ld	a0,24(a0)
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	008080e7          	jalr	8(ra) # 800037b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047b8:	874a                	mv	a4,s2
    800047ba:	5094                	lw	a3,32(s1)
    800047bc:	864e                	mv	a2,s3
    800047be:	4585                	li	a1,1
    800047c0:	6c88                	ld	a0,24(s1)
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	2aa080e7          	jalr	682(ra) # 80003a6c <readi>
    800047ca:	892a                	mv	s2,a0
    800047cc:	00a05563          	blez	a0,800047d6 <fileread+0x56>
      f->off += r;
    800047d0:	509c                	lw	a5,32(s1)
    800047d2:	9fa9                	addw	a5,a5,a0
    800047d4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047d6:	6c88                	ld	a0,24(s1)
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	0a2080e7          	jalr	162(ra) # 8000387a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047e0:	854a                	mv	a0,s2
    800047e2:	70a2                	ld	ra,40(sp)
    800047e4:	7402                	ld	s0,32(sp)
    800047e6:	64e2                	ld	s1,24(sp)
    800047e8:	6942                	ld	s2,16(sp)
    800047ea:	69a2                	ld	s3,8(sp)
    800047ec:	6145                	addi	sp,sp,48
    800047ee:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047f0:	6908                	ld	a0,16(a0)
    800047f2:	00000097          	auipc	ra,0x0
    800047f6:	418080e7          	jalr	1048(ra) # 80004c0a <piperead>
    800047fa:	892a                	mv	s2,a0
    800047fc:	b7d5                	j	800047e0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047fe:	02451783          	lh	a5,36(a0)
    80004802:	03079693          	slli	a3,a5,0x30
    80004806:	92c1                	srli	a3,a3,0x30
    80004808:	4725                	li	a4,9
    8000480a:	02d76863          	bltu	a4,a3,8000483a <fileread+0xba>
    8000480e:	0792                	slli	a5,a5,0x4
    80004810:	0001e717          	auipc	a4,0x1e
    80004814:	9a070713          	addi	a4,a4,-1632 # 800221b0 <devsw>
    80004818:	97ba                	add	a5,a5,a4
    8000481a:	639c                	ld	a5,0(a5)
    8000481c:	c38d                	beqz	a5,8000483e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000481e:	4505                	li	a0,1
    80004820:	9782                	jalr	a5
    80004822:	892a                	mv	s2,a0
    80004824:	bf75                	j	800047e0 <fileread+0x60>
    panic("fileread");
    80004826:	00004517          	auipc	a0,0x4
    8000482a:	e8250513          	addi	a0,a0,-382 # 800086a8 <syscalls+0x268>
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	d1a080e7          	jalr	-742(ra) # 80000548 <panic>
    return -1;
    80004836:	597d                	li	s2,-1
    80004838:	b765                	j	800047e0 <fileread+0x60>
      return -1;
    8000483a:	597d                	li	s2,-1
    8000483c:	b755                	j	800047e0 <fileread+0x60>
    8000483e:	597d                	li	s2,-1
    80004840:	b745                	j	800047e0 <fileread+0x60>

0000000080004842 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004842:	00954783          	lbu	a5,9(a0)
    80004846:	14078563          	beqz	a5,80004990 <filewrite+0x14e>
{
    8000484a:	715d                	addi	sp,sp,-80
    8000484c:	e486                	sd	ra,72(sp)
    8000484e:	e0a2                	sd	s0,64(sp)
    80004850:	fc26                	sd	s1,56(sp)
    80004852:	f84a                	sd	s2,48(sp)
    80004854:	f44e                	sd	s3,40(sp)
    80004856:	f052                	sd	s4,32(sp)
    80004858:	ec56                	sd	s5,24(sp)
    8000485a:	e85a                	sd	s6,16(sp)
    8000485c:	e45e                	sd	s7,8(sp)
    8000485e:	e062                	sd	s8,0(sp)
    80004860:	0880                	addi	s0,sp,80
    80004862:	892a                	mv	s2,a0
    80004864:	8aae                	mv	s5,a1
    80004866:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004868:	411c                	lw	a5,0(a0)
    8000486a:	4705                	li	a4,1
    8000486c:	02e78263          	beq	a5,a4,80004890 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004870:	470d                	li	a4,3
    80004872:	02e78563          	beq	a5,a4,8000489c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004876:	4709                	li	a4,2
    80004878:	10e79463          	bne	a5,a4,80004980 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000487c:	0ec05e63          	blez	a2,80004978 <filewrite+0x136>
    int i = 0;
    80004880:	4981                	li	s3,0
    80004882:	6b05                	lui	s6,0x1
    80004884:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004888:	6b85                	lui	s7,0x1
    8000488a:	c00b8b9b          	addiw	s7,s7,-1024
    8000488e:	a851                	j	80004922 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004890:	6908                	ld	a0,16(a0)
    80004892:	00000097          	auipc	ra,0x0
    80004896:	254080e7          	jalr	596(ra) # 80004ae6 <pipewrite>
    8000489a:	a85d                	j	80004950 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000489c:	02451783          	lh	a5,36(a0)
    800048a0:	03079693          	slli	a3,a5,0x30
    800048a4:	92c1                	srli	a3,a3,0x30
    800048a6:	4725                	li	a4,9
    800048a8:	0ed76663          	bltu	a4,a3,80004994 <filewrite+0x152>
    800048ac:	0792                	slli	a5,a5,0x4
    800048ae:	0001e717          	auipc	a4,0x1e
    800048b2:	90270713          	addi	a4,a4,-1790 # 800221b0 <devsw>
    800048b6:	97ba                	add	a5,a5,a4
    800048b8:	679c                	ld	a5,8(a5)
    800048ba:	cff9                	beqz	a5,80004998 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048bc:	4505                	li	a0,1
    800048be:	9782                	jalr	a5
    800048c0:	a841                	j	80004950 <filewrite+0x10e>
    800048c2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	8ae080e7          	jalr	-1874(ra) # 80004174 <begin_op>
      ilock(f->ip);
    800048ce:	01893503          	ld	a0,24(s2)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	ee6080e7          	jalr	-282(ra) # 800037b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048da:	8762                	mv	a4,s8
    800048dc:	02092683          	lw	a3,32(s2)
    800048e0:	01598633          	add	a2,s3,s5
    800048e4:	4585                	li	a1,1
    800048e6:	01893503          	ld	a0,24(s2)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	278080e7          	jalr	632(ra) # 80003b62 <writei>
    800048f2:	84aa                	mv	s1,a0
    800048f4:	02a05f63          	blez	a0,80004932 <filewrite+0xf0>
        f->off += r;
    800048f8:	02092783          	lw	a5,32(s2)
    800048fc:	9fa9                	addw	a5,a5,a0
    800048fe:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004902:	01893503          	ld	a0,24(s2)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	f74080e7          	jalr	-140(ra) # 8000387a <iunlock>
      end_op();
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	8e6080e7          	jalr	-1818(ra) # 800041f4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004916:	049c1963          	bne	s8,s1,80004968 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000491a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000491e:	0349d663          	bge	s3,s4,8000494a <filewrite+0x108>
      int n1 = n - i;
    80004922:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004926:	84be                	mv	s1,a5
    80004928:	2781                	sext.w	a5,a5
    8000492a:	f8fb5ce3          	bge	s6,a5,800048c2 <filewrite+0x80>
    8000492e:	84de                	mv	s1,s7
    80004930:	bf49                	j	800048c2 <filewrite+0x80>
      iunlock(f->ip);
    80004932:	01893503          	ld	a0,24(s2)
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	f44080e7          	jalr	-188(ra) # 8000387a <iunlock>
      end_op();
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	8b6080e7          	jalr	-1866(ra) # 800041f4 <end_op>
      if(r < 0)
    80004946:	fc04d8e3          	bgez	s1,80004916 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000494a:	8552                	mv	a0,s4
    8000494c:	033a1863          	bne	s4,s3,8000497c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004950:	60a6                	ld	ra,72(sp)
    80004952:	6406                	ld	s0,64(sp)
    80004954:	74e2                	ld	s1,56(sp)
    80004956:	7942                	ld	s2,48(sp)
    80004958:	79a2                	ld	s3,40(sp)
    8000495a:	7a02                	ld	s4,32(sp)
    8000495c:	6ae2                	ld	s5,24(sp)
    8000495e:	6b42                	ld	s6,16(sp)
    80004960:	6ba2                	ld	s7,8(sp)
    80004962:	6c02                	ld	s8,0(sp)
    80004964:	6161                	addi	sp,sp,80
    80004966:	8082                	ret
        panic("short filewrite");
    80004968:	00004517          	auipc	a0,0x4
    8000496c:	d5050513          	addi	a0,a0,-688 # 800086b8 <syscalls+0x278>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	bd8080e7          	jalr	-1064(ra) # 80000548 <panic>
    int i = 0;
    80004978:	4981                	li	s3,0
    8000497a:	bfc1                	j	8000494a <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000497c:	557d                	li	a0,-1
    8000497e:	bfc9                	j	80004950 <filewrite+0x10e>
    panic("filewrite");
    80004980:	00004517          	auipc	a0,0x4
    80004984:	d4850513          	addi	a0,a0,-696 # 800086c8 <syscalls+0x288>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	bc0080e7          	jalr	-1088(ra) # 80000548 <panic>
    return -1;
    80004990:	557d                	li	a0,-1
}
    80004992:	8082                	ret
      return -1;
    80004994:	557d                	li	a0,-1
    80004996:	bf6d                	j	80004950 <filewrite+0x10e>
    80004998:	557d                	li	a0,-1
    8000499a:	bf5d                	j	80004950 <filewrite+0x10e>

000000008000499c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000499c:	7179                	addi	sp,sp,-48
    8000499e:	f406                	sd	ra,40(sp)
    800049a0:	f022                	sd	s0,32(sp)
    800049a2:	ec26                	sd	s1,24(sp)
    800049a4:	e84a                	sd	s2,16(sp)
    800049a6:	e44e                	sd	s3,8(sp)
    800049a8:	e052                	sd	s4,0(sp)
    800049aa:	1800                	addi	s0,sp,48
    800049ac:	84aa                	mv	s1,a0
    800049ae:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049b0:	0005b023          	sd	zero,0(a1)
    800049b4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049b8:	00000097          	auipc	ra,0x0
    800049bc:	bd2080e7          	jalr	-1070(ra) # 8000458a <filealloc>
    800049c0:	e088                	sd	a0,0(s1)
    800049c2:	c551                	beqz	a0,80004a4e <pipealloc+0xb2>
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	bc6080e7          	jalr	-1082(ra) # 8000458a <filealloc>
    800049cc:	00aa3023          	sd	a0,0(s4)
    800049d0:	c92d                	beqz	a0,80004a42 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	1ba080e7          	jalr	442(ra) # 80000b8c <kalloc>
    800049da:	892a                	mv	s2,a0
    800049dc:	c125                	beqz	a0,80004a3c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049de:	4985                	li	s3,1
    800049e0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049e4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049e8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049ec:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049f0:	00004597          	auipc	a1,0x4
    800049f4:	ce858593          	addi	a1,a1,-792 # 800086d8 <syscalls+0x298>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	1f4080e7          	jalr	500(ra) # 80000bec <initlock>
  (*f0)->type = FD_PIPE;
    80004a00:	609c                	ld	a5,0(s1)
    80004a02:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a06:	609c                	ld	a5,0(s1)
    80004a08:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a0c:	609c                	ld	a5,0(s1)
    80004a0e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a12:	609c                	ld	a5,0(s1)
    80004a14:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a18:	000a3783          	ld	a5,0(s4)
    80004a1c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a20:	000a3783          	ld	a5,0(s4)
    80004a24:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a28:	000a3783          	ld	a5,0(s4)
    80004a2c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a30:	000a3783          	ld	a5,0(s4)
    80004a34:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a38:	4501                	li	a0,0
    80004a3a:	a025                	j	80004a62 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a3c:	6088                	ld	a0,0(s1)
    80004a3e:	e501                	bnez	a0,80004a46 <pipealloc+0xaa>
    80004a40:	a039                	j	80004a4e <pipealloc+0xb2>
    80004a42:	6088                	ld	a0,0(s1)
    80004a44:	c51d                	beqz	a0,80004a72 <pipealloc+0xd6>
    fileclose(*f0);
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	c00080e7          	jalr	-1024(ra) # 80004646 <fileclose>
  if(*f1)
    80004a4e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a52:	557d                	li	a0,-1
  if(*f1)
    80004a54:	c799                	beqz	a5,80004a62 <pipealloc+0xc6>
    fileclose(*f1);
    80004a56:	853e                	mv	a0,a5
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	bee080e7          	jalr	-1042(ra) # 80004646 <fileclose>
  return -1;
    80004a60:	557d                	li	a0,-1
}
    80004a62:	70a2                	ld	ra,40(sp)
    80004a64:	7402                	ld	s0,32(sp)
    80004a66:	64e2                	ld	s1,24(sp)
    80004a68:	6942                	ld	s2,16(sp)
    80004a6a:	69a2                	ld	s3,8(sp)
    80004a6c:	6a02                	ld	s4,0(sp)
    80004a6e:	6145                	addi	sp,sp,48
    80004a70:	8082                	ret
  return -1;
    80004a72:	557d                	li	a0,-1
    80004a74:	b7fd                	j	80004a62 <pipealloc+0xc6>

0000000080004a76 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a76:	1101                	addi	sp,sp,-32
    80004a78:	ec06                	sd	ra,24(sp)
    80004a7a:	e822                	sd	s0,16(sp)
    80004a7c:	e426                	sd	s1,8(sp)
    80004a7e:	e04a                	sd	s2,0(sp)
    80004a80:	1000                	addi	s0,sp,32
    80004a82:	84aa                	mv	s1,a0
    80004a84:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	1f6080e7          	jalr	502(ra) # 80000c7c <acquire>
  if(writable){
    80004a8e:	02090d63          	beqz	s2,80004ac8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a92:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a96:	21848513          	addi	a0,s1,536
    80004a9a:	ffffe097          	auipc	ra,0xffffe
    80004a9e:	99c080e7          	jalr	-1636(ra) # 80002436 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aa2:	2204b783          	ld	a5,544(s1)
    80004aa6:	eb95                	bnez	a5,80004ada <pipeclose+0x64>
    release(&pi->lock);
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	286080e7          	jalr	646(ra) # 80000d30 <release>
    kfree((char*)pi);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	fdc080e7          	jalr	-36(ra) # 80000a90 <kfree>
  } else
    release(&pi->lock);
}
    80004abc:	60e2                	ld	ra,24(sp)
    80004abe:	6442                	ld	s0,16(sp)
    80004ac0:	64a2                	ld	s1,8(sp)
    80004ac2:	6902                	ld	s2,0(sp)
    80004ac4:	6105                	addi	sp,sp,32
    80004ac6:	8082                	ret
    pi->readopen = 0;
    80004ac8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004acc:	21c48513          	addi	a0,s1,540
    80004ad0:	ffffe097          	auipc	ra,0xffffe
    80004ad4:	966080e7          	jalr	-1690(ra) # 80002436 <wakeup>
    80004ad8:	b7e9                	j	80004aa2 <pipeclose+0x2c>
    release(&pi->lock);
    80004ada:	8526                	mv	a0,s1
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	254080e7          	jalr	596(ra) # 80000d30 <release>
}
    80004ae4:	bfe1                	j	80004abc <pipeclose+0x46>

0000000080004ae6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ae6:	7119                	addi	sp,sp,-128
    80004ae8:	fc86                	sd	ra,120(sp)
    80004aea:	f8a2                	sd	s0,112(sp)
    80004aec:	f4a6                	sd	s1,104(sp)
    80004aee:	f0ca                	sd	s2,96(sp)
    80004af0:	ecce                	sd	s3,88(sp)
    80004af2:	e8d2                	sd	s4,80(sp)
    80004af4:	e4d6                	sd	s5,72(sp)
    80004af6:	e0da                	sd	s6,64(sp)
    80004af8:	fc5e                	sd	s7,56(sp)
    80004afa:	f862                	sd	s8,48(sp)
    80004afc:	f466                	sd	s9,40(sp)
    80004afe:	f06a                	sd	s10,32(sp)
    80004b00:	ec6e                	sd	s11,24(sp)
    80004b02:	0100                	addi	s0,sp,128
    80004b04:	84aa                	mv	s1,a0
    80004b06:	8cae                	mv	s9,a1
    80004b08:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b0a:	ffffd097          	auipc	ra,0xffffd
    80004b0e:	f40080e7          	jalr	-192(ra) # 80001a4a <myproc>
    80004b12:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b14:	8526                	mv	a0,s1
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	166080e7          	jalr	358(ra) # 80000c7c <acquire>
  for(i = 0; i < n; i++){
    80004b1e:	0d605963          	blez	s6,80004bf0 <pipewrite+0x10a>
    80004b22:	89a6                	mv	s3,s1
    80004b24:	3b7d                	addiw	s6,s6,-1
    80004b26:	1b02                	slli	s6,s6,0x20
    80004b28:	020b5b13          	srli	s6,s6,0x20
    80004b2c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b2e:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b32:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b36:	5dfd                	li	s11,-1
    80004b38:	000b8d1b          	sext.w	s10,s7
    80004b3c:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b3e:	2184a783          	lw	a5,536(s1)
    80004b42:	21c4a703          	lw	a4,540(s1)
    80004b46:	2007879b          	addiw	a5,a5,512
    80004b4a:	02f71b63          	bne	a4,a5,80004b80 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b4e:	2204a783          	lw	a5,544(s1)
    80004b52:	cbad                	beqz	a5,80004bc4 <pipewrite+0xde>
    80004b54:	03092783          	lw	a5,48(s2)
    80004b58:	e7b5                	bnez	a5,80004bc4 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b5a:	8556                	mv	a0,s5
    80004b5c:	ffffe097          	auipc	ra,0xffffe
    80004b60:	8da080e7          	jalr	-1830(ra) # 80002436 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b64:	85ce                	mv	a1,s3
    80004b66:	8552                	mv	a0,s4
    80004b68:	ffffd097          	auipc	ra,0xffffd
    80004b6c:	748080e7          	jalr	1864(ra) # 800022b0 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b70:	2184a783          	lw	a5,536(s1)
    80004b74:	21c4a703          	lw	a4,540(s1)
    80004b78:	2007879b          	addiw	a5,a5,512
    80004b7c:	fcf709e3          	beq	a4,a5,80004b4e <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b80:	4685                	li	a3,1
    80004b82:	019b8633          	add	a2,s7,s9
    80004b86:	f8f40593          	addi	a1,s0,-113
    80004b8a:	05093503          	ld	a0,80(s2)
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	c3c080e7          	jalr	-964(ra) # 800017ca <copyin>
    80004b96:	05b50e63          	beq	a0,s11,80004bf2 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b9a:	21c4a783          	lw	a5,540(s1)
    80004b9e:	0017871b          	addiw	a4,a5,1
    80004ba2:	20e4ae23          	sw	a4,540(s1)
    80004ba6:	1ff7f793          	andi	a5,a5,511
    80004baa:	97a6                	add	a5,a5,s1
    80004bac:	f8f44703          	lbu	a4,-113(s0)
    80004bb0:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bb4:	001d0c1b          	addiw	s8,s10,1
    80004bb8:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004bbc:	036b8b63          	beq	s7,s6,80004bf2 <pipewrite+0x10c>
    80004bc0:	8bbe                	mv	s7,a5
    80004bc2:	bf9d                	j	80004b38 <pipewrite+0x52>
        release(&pi->lock);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	16a080e7          	jalr	362(ra) # 80000d30 <release>
        return -1;
    80004bce:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004bd0:	8562                	mv	a0,s8
    80004bd2:	70e6                	ld	ra,120(sp)
    80004bd4:	7446                	ld	s0,112(sp)
    80004bd6:	74a6                	ld	s1,104(sp)
    80004bd8:	7906                	ld	s2,96(sp)
    80004bda:	69e6                	ld	s3,88(sp)
    80004bdc:	6a46                	ld	s4,80(sp)
    80004bde:	6aa6                	ld	s5,72(sp)
    80004be0:	6b06                	ld	s6,64(sp)
    80004be2:	7be2                	ld	s7,56(sp)
    80004be4:	7c42                	ld	s8,48(sp)
    80004be6:	7ca2                	ld	s9,40(sp)
    80004be8:	7d02                	ld	s10,32(sp)
    80004bea:	6de2                	ld	s11,24(sp)
    80004bec:	6109                	addi	sp,sp,128
    80004bee:	8082                	ret
  for(i = 0; i < n; i++){
    80004bf0:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bf2:	21848513          	addi	a0,s1,536
    80004bf6:	ffffe097          	auipc	ra,0xffffe
    80004bfa:	840080e7          	jalr	-1984(ra) # 80002436 <wakeup>
  release(&pi->lock);
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	130080e7          	jalr	304(ra) # 80000d30 <release>
  return i;
    80004c08:	b7e1                	j	80004bd0 <pipewrite+0xea>

0000000080004c0a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c0a:	715d                	addi	sp,sp,-80
    80004c0c:	e486                	sd	ra,72(sp)
    80004c0e:	e0a2                	sd	s0,64(sp)
    80004c10:	fc26                	sd	s1,56(sp)
    80004c12:	f84a                	sd	s2,48(sp)
    80004c14:	f44e                	sd	s3,40(sp)
    80004c16:	f052                	sd	s4,32(sp)
    80004c18:	ec56                	sd	s5,24(sp)
    80004c1a:	e85a                	sd	s6,16(sp)
    80004c1c:	0880                	addi	s0,sp,80
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	892e                	mv	s2,a1
    80004c22:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	e26080e7          	jalr	-474(ra) # 80001a4a <myproc>
    80004c2c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c2e:	8b26                	mv	s6,s1
    80004c30:	8526                	mv	a0,s1
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	04a080e7          	jalr	74(ra) # 80000c7c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c3a:	2184a703          	lw	a4,536(s1)
    80004c3e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c42:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c46:	02f71463          	bne	a4,a5,80004c6e <piperead+0x64>
    80004c4a:	2244a783          	lw	a5,548(s1)
    80004c4e:	c385                	beqz	a5,80004c6e <piperead+0x64>
    if(pr->killed){
    80004c50:	030a2783          	lw	a5,48(s4)
    80004c54:	ebc1                	bnez	a5,80004ce4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c56:	85da                	mv	a1,s6
    80004c58:	854e                	mv	a0,s3
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	656080e7          	jalr	1622(ra) # 800022b0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c62:	2184a703          	lw	a4,536(s1)
    80004c66:	21c4a783          	lw	a5,540(s1)
    80004c6a:	fef700e3          	beq	a4,a5,80004c4a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6e:	09505263          	blez	s5,80004cf2 <piperead+0xe8>
    80004c72:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c74:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c76:	2184a783          	lw	a5,536(s1)
    80004c7a:	21c4a703          	lw	a4,540(s1)
    80004c7e:	02f70d63          	beq	a4,a5,80004cb8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c82:	0017871b          	addiw	a4,a5,1
    80004c86:	20e4ac23          	sw	a4,536(s1)
    80004c8a:	1ff7f793          	andi	a5,a5,511
    80004c8e:	97a6                	add	a5,a5,s1
    80004c90:	0187c783          	lbu	a5,24(a5)
    80004c94:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c98:	4685                	li	a3,1
    80004c9a:	fbf40613          	addi	a2,s0,-65
    80004c9e:	85ca                	mv	a1,s2
    80004ca0:	050a3503          	ld	a0,80(s4)
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	a9a080e7          	jalr	-1382(ra) # 8000173e <copyout>
    80004cac:	01650663          	beq	a0,s6,80004cb8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb0:	2985                	addiw	s3,s3,1
    80004cb2:	0905                	addi	s2,s2,1
    80004cb4:	fd3a91e3          	bne	s5,s3,80004c76 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cb8:	21c48513          	addi	a0,s1,540
    80004cbc:	ffffd097          	auipc	ra,0xffffd
    80004cc0:	77a080e7          	jalr	1914(ra) # 80002436 <wakeup>
  release(&pi->lock);
    80004cc4:	8526                	mv	a0,s1
    80004cc6:	ffffc097          	auipc	ra,0xffffc
    80004cca:	06a080e7          	jalr	106(ra) # 80000d30 <release>
  return i;
}
    80004cce:	854e                	mv	a0,s3
    80004cd0:	60a6                	ld	ra,72(sp)
    80004cd2:	6406                	ld	s0,64(sp)
    80004cd4:	74e2                	ld	s1,56(sp)
    80004cd6:	7942                	ld	s2,48(sp)
    80004cd8:	79a2                	ld	s3,40(sp)
    80004cda:	7a02                	ld	s4,32(sp)
    80004cdc:	6ae2                	ld	s5,24(sp)
    80004cde:	6b42                	ld	s6,16(sp)
    80004ce0:	6161                	addi	sp,sp,80
    80004ce2:	8082                	ret
      release(&pi->lock);
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	04a080e7          	jalr	74(ra) # 80000d30 <release>
      return -1;
    80004cee:	59fd                	li	s3,-1
    80004cf0:	bff9                	j	80004cce <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf2:	4981                	li	s3,0
    80004cf4:	b7d1                	j	80004cb8 <piperead+0xae>

0000000080004cf6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cf6:	df010113          	addi	sp,sp,-528
    80004cfa:	20113423          	sd	ra,520(sp)
    80004cfe:	20813023          	sd	s0,512(sp)
    80004d02:	ffa6                	sd	s1,504(sp)
    80004d04:	fbca                	sd	s2,496(sp)
    80004d06:	f7ce                	sd	s3,488(sp)
    80004d08:	f3d2                	sd	s4,480(sp)
    80004d0a:	efd6                	sd	s5,472(sp)
    80004d0c:	ebda                	sd	s6,464(sp)
    80004d0e:	e7de                	sd	s7,456(sp)
    80004d10:	e3e2                	sd	s8,448(sp)
    80004d12:	ff66                	sd	s9,440(sp)
    80004d14:	fb6a                	sd	s10,432(sp)
    80004d16:	f76e                	sd	s11,424(sp)
    80004d18:	0c00                	addi	s0,sp,528
    80004d1a:	84aa                	mv	s1,a0
    80004d1c:	dea43c23          	sd	a0,-520(s0)
    80004d20:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	d26080e7          	jalr	-730(ra) # 80001a4a <myproc>
    80004d2c:	892a                	mv	s2,a0

  begin_op();
    80004d2e:	fffff097          	auipc	ra,0xfffff
    80004d32:	446080e7          	jalr	1094(ra) # 80004174 <begin_op>

  if((ip = namei(path)) == 0){
    80004d36:	8526                	mv	a0,s1
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	230080e7          	jalr	560(ra) # 80003f68 <namei>
    80004d40:	c92d                	beqz	a0,80004db2 <exec+0xbc>
    80004d42:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	a74080e7          	jalr	-1420(ra) # 800037b8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d4c:	04000713          	li	a4,64
    80004d50:	4681                	li	a3,0
    80004d52:	e4840613          	addi	a2,s0,-440
    80004d56:	4581                	li	a1,0
    80004d58:	8526                	mv	a0,s1
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	d12080e7          	jalr	-750(ra) # 80003a6c <readi>
    80004d62:	04000793          	li	a5,64
    80004d66:	00f51a63          	bne	a0,a5,80004d7a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d6a:	e4842703          	lw	a4,-440(s0)
    80004d6e:	464c47b7          	lui	a5,0x464c4
    80004d72:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d76:	04f70463          	beq	a4,a5,80004dbe <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	c9e080e7          	jalr	-866(ra) # 80003a1a <iunlockput>
    end_op();
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	470080e7          	jalr	1136(ra) # 800041f4 <end_op>
  }
  return -1;
    80004d8c:	557d                	li	a0,-1
}
    80004d8e:	20813083          	ld	ra,520(sp)
    80004d92:	20013403          	ld	s0,512(sp)
    80004d96:	74fe                	ld	s1,504(sp)
    80004d98:	795e                	ld	s2,496(sp)
    80004d9a:	79be                	ld	s3,488(sp)
    80004d9c:	7a1e                	ld	s4,480(sp)
    80004d9e:	6afe                	ld	s5,472(sp)
    80004da0:	6b5e                	ld	s6,464(sp)
    80004da2:	6bbe                	ld	s7,456(sp)
    80004da4:	6c1e                	ld	s8,448(sp)
    80004da6:	7cfa                	ld	s9,440(sp)
    80004da8:	7d5a                	ld	s10,432(sp)
    80004daa:	7dba                	ld	s11,424(sp)
    80004dac:	21010113          	addi	sp,sp,528
    80004db0:	8082                	ret
    end_op();
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	442080e7          	jalr	1090(ra) # 800041f4 <end_op>
    return -1;
    80004dba:	557d                	li	a0,-1
    80004dbc:	bfc9                	j	80004d8e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dbe:	854a                	mv	a0,s2
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	d4e080e7          	jalr	-690(ra) # 80001b0e <proc_pagetable>
    80004dc8:	8baa                	mv	s7,a0
    80004dca:	d945                	beqz	a0,80004d7a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dcc:	e6842983          	lw	s3,-408(s0)
    80004dd0:	e8045783          	lhu	a5,-384(s0)
    80004dd4:	c7ad                	beqz	a5,80004e3e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dd6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dd8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dda:	6c85                	lui	s9,0x1
    80004ddc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004de0:	def43823          	sd	a5,-528(s0)
    80004de4:	a42d                	j	8000500e <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004de6:	00004517          	auipc	a0,0x4
    80004dea:	8fa50513          	addi	a0,a0,-1798 # 800086e0 <syscalls+0x2a0>
    80004dee:	ffffb097          	auipc	ra,0xffffb
    80004df2:	75a080e7          	jalr	1882(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004df6:	8756                	mv	a4,s5
    80004df8:	012d86bb          	addw	a3,s11,s2
    80004dfc:	4581                	li	a1,0
    80004dfe:	8526                	mv	a0,s1
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	c6c080e7          	jalr	-916(ra) # 80003a6c <readi>
    80004e08:	2501                	sext.w	a0,a0
    80004e0a:	1aaa9963          	bne	s5,a0,80004fbc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e0e:	6785                	lui	a5,0x1
    80004e10:	0127893b          	addw	s2,a5,s2
    80004e14:	77fd                	lui	a5,0xfffff
    80004e16:	01478a3b          	addw	s4,a5,s4
    80004e1a:	1f897163          	bgeu	s2,s8,80004ffc <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e1e:	02091593          	slli	a1,s2,0x20
    80004e22:	9181                	srli	a1,a1,0x20
    80004e24:	95ea                	add	a1,a1,s10
    80004e26:	855e                	mv	a0,s7
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	2e2080e7          	jalr	738(ra) # 8000110a <walkaddr>
    80004e30:	862a                	mv	a2,a0
    if(pa == 0)
    80004e32:	d955                	beqz	a0,80004de6 <exec+0xf0>
      n = PGSIZE;
    80004e34:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e36:	fd9a70e3          	bgeu	s4,s9,80004df6 <exec+0x100>
      n = sz - i;
    80004e3a:	8ad2                	mv	s5,s4
    80004e3c:	bf6d                	j	80004df6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e3e:	4901                	li	s2,0
  iunlockput(ip);
    80004e40:	8526                	mv	a0,s1
    80004e42:	fffff097          	auipc	ra,0xfffff
    80004e46:	bd8080e7          	jalr	-1064(ra) # 80003a1a <iunlockput>
  end_op();
    80004e4a:	fffff097          	auipc	ra,0xfffff
    80004e4e:	3aa080e7          	jalr	938(ra) # 800041f4 <end_op>
  p = myproc();
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	bf8080e7          	jalr	-1032(ra) # 80001a4a <myproc>
    80004e5a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e5c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e60:	6785                	lui	a5,0x1
    80004e62:	17fd                	addi	a5,a5,-1
    80004e64:	993e                	add	s2,s2,a5
    80004e66:	757d                	lui	a0,0xfffff
    80004e68:	00a977b3          	and	a5,s2,a0
    80004e6c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e70:	6609                	lui	a2,0x2
    80004e72:	963e                	add	a2,a2,a5
    80004e74:	85be                	mv	a1,a5
    80004e76:	855e                	mv	a0,s7
    80004e78:	ffffc097          	auipc	ra,0xffffc
    80004e7c:	676080e7          	jalr	1654(ra) # 800014ee <uvmalloc>
    80004e80:	8b2a                	mv	s6,a0
  ip = 0;
    80004e82:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e84:	12050c63          	beqz	a0,80004fbc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e88:	75f9                	lui	a1,0xffffe
    80004e8a:	95aa                	add	a1,a1,a0
    80004e8c:	855e                	mv	a0,s7
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	87e080e7          	jalr	-1922(ra) # 8000170c <uvmclear>
  stackbase = sp - PGSIZE;
    80004e96:	7c7d                	lui	s8,0xfffff
    80004e98:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e9a:	e0043783          	ld	a5,-512(s0)
    80004e9e:	6388                	ld	a0,0(a5)
    80004ea0:	c535                	beqz	a0,80004f0c <exec+0x216>
    80004ea2:	e8840993          	addi	s3,s0,-376
    80004ea6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004eaa:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	054080e7          	jalr	84(ra) # 80000f00 <strlen>
    80004eb4:	2505                	addiw	a0,a0,1
    80004eb6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eba:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ebe:	13896363          	bltu	s2,s8,80004fe4 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ec2:	e0043d83          	ld	s11,-512(s0)
    80004ec6:	000dba03          	ld	s4,0(s11)
    80004eca:	8552                	mv	a0,s4
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	034080e7          	jalr	52(ra) # 80000f00 <strlen>
    80004ed4:	0015069b          	addiw	a3,a0,1
    80004ed8:	8652                	mv	a2,s4
    80004eda:	85ca                	mv	a1,s2
    80004edc:	855e                	mv	a0,s7
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	860080e7          	jalr	-1952(ra) # 8000173e <copyout>
    80004ee6:	10054363          	bltz	a0,80004fec <exec+0x2f6>
    ustack[argc] = sp;
    80004eea:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eee:	0485                	addi	s1,s1,1
    80004ef0:	008d8793          	addi	a5,s11,8
    80004ef4:	e0f43023          	sd	a5,-512(s0)
    80004ef8:	008db503          	ld	a0,8(s11)
    80004efc:	c911                	beqz	a0,80004f10 <exec+0x21a>
    if(argc >= MAXARG)
    80004efe:	09a1                	addi	s3,s3,8
    80004f00:	fb3c96e3          	bne	s9,s3,80004eac <exec+0x1b6>
  sz = sz1;
    80004f04:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f08:	4481                	li	s1,0
    80004f0a:	a84d                	j	80004fbc <exec+0x2c6>
  sp = sz;
    80004f0c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f0e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f10:	00349793          	slli	a5,s1,0x3
    80004f14:	f9040713          	addi	a4,s0,-112
    80004f18:	97ba                	add	a5,a5,a4
    80004f1a:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f1e:	00148693          	addi	a3,s1,1
    80004f22:	068e                	slli	a3,a3,0x3
    80004f24:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f28:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f2c:	01897663          	bgeu	s2,s8,80004f38 <exec+0x242>
  sz = sz1;
    80004f30:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f34:	4481                	li	s1,0
    80004f36:	a059                	j	80004fbc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f38:	e8840613          	addi	a2,s0,-376
    80004f3c:	85ca                	mv	a1,s2
    80004f3e:	855e                	mv	a0,s7
    80004f40:	ffffc097          	auipc	ra,0xffffc
    80004f44:	7fe080e7          	jalr	2046(ra) # 8000173e <copyout>
    80004f48:	0a054663          	bltz	a0,80004ff4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f4c:	058ab783          	ld	a5,88(s5)
    80004f50:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f54:	df843783          	ld	a5,-520(s0)
    80004f58:	0007c703          	lbu	a4,0(a5)
    80004f5c:	cf11                	beqz	a4,80004f78 <exec+0x282>
    80004f5e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f60:	02f00693          	li	a3,47
    80004f64:	a029                	j	80004f6e <exec+0x278>
  for(last=s=path; *s; s++)
    80004f66:	0785                	addi	a5,a5,1
    80004f68:	fff7c703          	lbu	a4,-1(a5)
    80004f6c:	c711                	beqz	a4,80004f78 <exec+0x282>
    if(*s == '/')
    80004f6e:	fed71ce3          	bne	a4,a3,80004f66 <exec+0x270>
      last = s+1;
    80004f72:	def43c23          	sd	a5,-520(s0)
    80004f76:	bfc5                	j	80004f66 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f78:	4641                	li	a2,16
    80004f7a:	df843583          	ld	a1,-520(s0)
    80004f7e:	158a8513          	addi	a0,s5,344
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	f4c080e7          	jalr	-180(ra) # 80000ece <safestrcpy>
  oldpagetable = p->pagetable;
    80004f8a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f8e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f92:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f96:	058ab783          	ld	a5,88(s5)
    80004f9a:	e6043703          	ld	a4,-416(s0)
    80004f9e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fa0:	058ab783          	ld	a5,88(s5)
    80004fa4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fa8:	85ea                	mv	a1,s10
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	c00080e7          	jalr	-1024(ra) # 80001baa <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fb2:	0004851b          	sext.w	a0,s1
    80004fb6:	bbe1                	j	80004d8e <exec+0x98>
    80004fb8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fbc:	e0843583          	ld	a1,-504(s0)
    80004fc0:	855e                	mv	a0,s7
    80004fc2:	ffffd097          	auipc	ra,0xffffd
    80004fc6:	be8080e7          	jalr	-1048(ra) # 80001baa <proc_freepagetable>
  if(ip){
    80004fca:	da0498e3          	bnez	s1,80004d7a <exec+0x84>
  return -1;
    80004fce:	557d                	li	a0,-1
    80004fd0:	bb7d                	j	80004d8e <exec+0x98>
    80004fd2:	e1243423          	sd	s2,-504(s0)
    80004fd6:	b7dd                	j	80004fbc <exec+0x2c6>
    80004fd8:	e1243423          	sd	s2,-504(s0)
    80004fdc:	b7c5                	j	80004fbc <exec+0x2c6>
    80004fde:	e1243423          	sd	s2,-504(s0)
    80004fe2:	bfe9                	j	80004fbc <exec+0x2c6>
  sz = sz1;
    80004fe4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fe8:	4481                	li	s1,0
    80004fea:	bfc9                	j	80004fbc <exec+0x2c6>
  sz = sz1;
    80004fec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff0:	4481                	li	s1,0
    80004ff2:	b7e9                	j	80004fbc <exec+0x2c6>
  sz = sz1;
    80004ff4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff8:	4481                	li	s1,0
    80004ffa:	b7c9                	j	80004fbc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ffc:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005000:	2b05                	addiw	s6,s6,1
    80005002:	0389899b          	addiw	s3,s3,56
    80005006:	e8045783          	lhu	a5,-384(s0)
    8000500a:	e2fb5be3          	bge	s6,a5,80004e40 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000500e:	2981                	sext.w	s3,s3
    80005010:	03800713          	li	a4,56
    80005014:	86ce                	mv	a3,s3
    80005016:	e1040613          	addi	a2,s0,-496
    8000501a:	4581                	li	a1,0
    8000501c:	8526                	mv	a0,s1
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	a4e080e7          	jalr	-1458(ra) # 80003a6c <readi>
    80005026:	03800793          	li	a5,56
    8000502a:	f8f517e3          	bne	a0,a5,80004fb8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000502e:	e1042783          	lw	a5,-496(s0)
    80005032:	4705                	li	a4,1
    80005034:	fce796e3          	bne	a5,a4,80005000 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005038:	e3843603          	ld	a2,-456(s0)
    8000503c:	e3043783          	ld	a5,-464(s0)
    80005040:	f8f669e3          	bltu	a2,a5,80004fd2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005044:	e2043783          	ld	a5,-480(s0)
    80005048:	963e                	add	a2,a2,a5
    8000504a:	f8f667e3          	bltu	a2,a5,80004fd8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000504e:	85ca                	mv	a1,s2
    80005050:	855e                	mv	a0,s7
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	49c080e7          	jalr	1180(ra) # 800014ee <uvmalloc>
    8000505a:	e0a43423          	sd	a0,-504(s0)
    8000505e:	d141                	beqz	a0,80004fde <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005060:	e2043d03          	ld	s10,-480(s0)
    80005064:	df043783          	ld	a5,-528(s0)
    80005068:	00fd77b3          	and	a5,s10,a5
    8000506c:	fba1                	bnez	a5,80004fbc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000506e:	e1842d83          	lw	s11,-488(s0)
    80005072:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005076:	f80c03e3          	beqz	s8,80004ffc <exec+0x306>
    8000507a:	8a62                	mv	s4,s8
    8000507c:	4901                	li	s2,0
    8000507e:	b345                	j	80004e1e <exec+0x128>

0000000080005080 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005080:	7179                	addi	sp,sp,-48
    80005082:	f406                	sd	ra,40(sp)
    80005084:	f022                	sd	s0,32(sp)
    80005086:	ec26                	sd	s1,24(sp)
    80005088:	e84a                	sd	s2,16(sp)
    8000508a:	1800                	addi	s0,sp,48
    8000508c:	892e                	mv	s2,a1
    8000508e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005090:	fdc40593          	addi	a1,s0,-36
    80005094:	ffffe097          	auipc	ra,0xffffe
    80005098:	b1c080e7          	jalr	-1252(ra) # 80002bb0 <argint>
    8000509c:	04054063          	bltz	a0,800050dc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050a0:	fdc42703          	lw	a4,-36(s0)
    800050a4:	47bd                	li	a5,15
    800050a6:	02e7ed63          	bltu	a5,a4,800050e0 <argfd+0x60>
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	9a0080e7          	jalr	-1632(ra) # 80001a4a <myproc>
    800050b2:	fdc42703          	lw	a4,-36(s0)
    800050b6:	01a70793          	addi	a5,a4,26
    800050ba:	078e                	slli	a5,a5,0x3
    800050bc:	953e                	add	a0,a0,a5
    800050be:	611c                	ld	a5,0(a0)
    800050c0:	c395                	beqz	a5,800050e4 <argfd+0x64>
    return -1;
  if(pfd)
    800050c2:	00090463          	beqz	s2,800050ca <argfd+0x4a>
    *pfd = fd;
    800050c6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050ca:	4501                	li	a0,0
  if(pf)
    800050cc:	c091                	beqz	s1,800050d0 <argfd+0x50>
    *pf = f;
    800050ce:	e09c                	sd	a5,0(s1)
}
    800050d0:	70a2                	ld	ra,40(sp)
    800050d2:	7402                	ld	s0,32(sp)
    800050d4:	64e2                	ld	s1,24(sp)
    800050d6:	6942                	ld	s2,16(sp)
    800050d8:	6145                	addi	sp,sp,48
    800050da:	8082                	ret
    return -1;
    800050dc:	557d                	li	a0,-1
    800050de:	bfcd                	j	800050d0 <argfd+0x50>
    return -1;
    800050e0:	557d                	li	a0,-1
    800050e2:	b7fd                	j	800050d0 <argfd+0x50>
    800050e4:	557d                	li	a0,-1
    800050e6:	b7ed                	j	800050d0 <argfd+0x50>

00000000800050e8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050e8:	1101                	addi	sp,sp,-32
    800050ea:	ec06                	sd	ra,24(sp)
    800050ec:	e822                	sd	s0,16(sp)
    800050ee:	e426                	sd	s1,8(sp)
    800050f0:	1000                	addi	s0,sp,32
    800050f2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050f4:	ffffd097          	auipc	ra,0xffffd
    800050f8:	956080e7          	jalr	-1706(ra) # 80001a4a <myproc>
    800050fc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050fe:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    80005102:	4501                	li	a0,0
    80005104:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005106:	6398                	ld	a4,0(a5)
    80005108:	cb19                	beqz	a4,8000511e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000510a:	2505                	addiw	a0,a0,1
    8000510c:	07a1                	addi	a5,a5,8
    8000510e:	fed51ce3          	bne	a0,a3,80005106 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005112:	557d                	li	a0,-1
}
    80005114:	60e2                	ld	ra,24(sp)
    80005116:	6442                	ld	s0,16(sp)
    80005118:	64a2                	ld	s1,8(sp)
    8000511a:	6105                	addi	sp,sp,32
    8000511c:	8082                	ret
      p->ofile[fd] = f;
    8000511e:	01a50793          	addi	a5,a0,26
    80005122:	078e                	slli	a5,a5,0x3
    80005124:	963e                	add	a2,a2,a5
    80005126:	e204                	sd	s1,0(a2)
      return fd;
    80005128:	b7f5                	j	80005114 <fdalloc+0x2c>

000000008000512a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000512a:	715d                	addi	sp,sp,-80
    8000512c:	e486                	sd	ra,72(sp)
    8000512e:	e0a2                	sd	s0,64(sp)
    80005130:	fc26                	sd	s1,56(sp)
    80005132:	f84a                	sd	s2,48(sp)
    80005134:	f44e                	sd	s3,40(sp)
    80005136:	f052                	sd	s4,32(sp)
    80005138:	ec56                	sd	s5,24(sp)
    8000513a:	0880                	addi	s0,sp,80
    8000513c:	89ae                	mv	s3,a1
    8000513e:	8ab2                	mv	s5,a2
    80005140:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005142:	fb040593          	addi	a1,s0,-80
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	e40080e7          	jalr	-448(ra) # 80003f86 <nameiparent>
    8000514e:	892a                	mv	s2,a0
    80005150:	12050f63          	beqz	a0,8000528e <create+0x164>
    return 0;

  ilock(dp);
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	664080e7          	jalr	1636(ra) # 800037b8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000515c:	4601                	li	a2,0
    8000515e:	fb040593          	addi	a1,s0,-80
    80005162:	854a                	mv	a0,s2
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	b32080e7          	jalr	-1230(ra) # 80003c96 <dirlookup>
    8000516c:	84aa                	mv	s1,a0
    8000516e:	c921                	beqz	a0,800051be <create+0x94>
    iunlockput(dp);
    80005170:	854a                	mv	a0,s2
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	8a8080e7          	jalr	-1880(ra) # 80003a1a <iunlockput>
    ilock(ip);
    8000517a:	8526                	mv	a0,s1
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	63c080e7          	jalr	1596(ra) # 800037b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005184:	2981                	sext.w	s3,s3
    80005186:	4789                	li	a5,2
    80005188:	02f99463          	bne	s3,a5,800051b0 <create+0x86>
    8000518c:	0444d783          	lhu	a5,68(s1)
    80005190:	37f9                	addiw	a5,a5,-2
    80005192:	17c2                	slli	a5,a5,0x30
    80005194:	93c1                	srli	a5,a5,0x30
    80005196:	4705                	li	a4,1
    80005198:	00f76c63          	bltu	a4,a5,800051b0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000519c:	8526                	mv	a0,s1
    8000519e:	60a6                	ld	ra,72(sp)
    800051a0:	6406                	ld	s0,64(sp)
    800051a2:	74e2                	ld	s1,56(sp)
    800051a4:	7942                	ld	s2,48(sp)
    800051a6:	79a2                	ld	s3,40(sp)
    800051a8:	7a02                	ld	s4,32(sp)
    800051aa:	6ae2                	ld	s5,24(sp)
    800051ac:	6161                	addi	sp,sp,80
    800051ae:	8082                	ret
    iunlockput(ip);
    800051b0:	8526                	mv	a0,s1
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	868080e7          	jalr	-1944(ra) # 80003a1a <iunlockput>
    return 0;
    800051ba:	4481                	li	s1,0
    800051bc:	b7c5                	j	8000519c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051be:	85ce                	mv	a1,s3
    800051c0:	00092503          	lw	a0,0(s2)
    800051c4:	ffffe097          	auipc	ra,0xffffe
    800051c8:	45c080e7          	jalr	1116(ra) # 80003620 <ialloc>
    800051cc:	84aa                	mv	s1,a0
    800051ce:	c529                	beqz	a0,80005218 <create+0xee>
  ilock(ip);
    800051d0:	ffffe097          	auipc	ra,0xffffe
    800051d4:	5e8080e7          	jalr	1512(ra) # 800037b8 <ilock>
  ip->major = major;
    800051d8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051dc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051e0:	4785                	li	a5,1
    800051e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051e6:	8526                	mv	a0,s1
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	506080e7          	jalr	1286(ra) # 800036ee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051f0:	2981                	sext.w	s3,s3
    800051f2:	4785                	li	a5,1
    800051f4:	02f98a63          	beq	s3,a5,80005228 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051f8:	40d0                	lw	a2,4(s1)
    800051fa:	fb040593          	addi	a1,s0,-80
    800051fe:	854a                	mv	a0,s2
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	ca6080e7          	jalr	-858(ra) # 80003ea6 <dirlink>
    80005208:	06054b63          	bltz	a0,8000527e <create+0x154>
  iunlockput(dp);
    8000520c:	854a                	mv	a0,s2
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	80c080e7          	jalr	-2036(ra) # 80003a1a <iunlockput>
  return ip;
    80005216:	b759                	j	8000519c <create+0x72>
    panic("create: ialloc");
    80005218:	00003517          	auipc	a0,0x3
    8000521c:	4e850513          	addi	a0,a0,1256 # 80008700 <syscalls+0x2c0>
    80005220:	ffffb097          	auipc	ra,0xffffb
    80005224:	328080e7          	jalr	808(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005228:	04a95783          	lhu	a5,74(s2)
    8000522c:	2785                	addiw	a5,a5,1
    8000522e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005232:	854a                	mv	a0,s2
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	4ba080e7          	jalr	1210(ra) # 800036ee <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000523c:	40d0                	lw	a2,4(s1)
    8000523e:	00003597          	auipc	a1,0x3
    80005242:	4d258593          	addi	a1,a1,1234 # 80008710 <syscalls+0x2d0>
    80005246:	8526                	mv	a0,s1
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	c5e080e7          	jalr	-930(ra) # 80003ea6 <dirlink>
    80005250:	00054f63          	bltz	a0,8000526e <create+0x144>
    80005254:	00492603          	lw	a2,4(s2)
    80005258:	00003597          	auipc	a1,0x3
    8000525c:	4c058593          	addi	a1,a1,1216 # 80008718 <syscalls+0x2d8>
    80005260:	8526                	mv	a0,s1
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	c44080e7          	jalr	-956(ra) # 80003ea6 <dirlink>
    8000526a:	f80557e3          	bgez	a0,800051f8 <create+0xce>
      panic("create dots");
    8000526e:	00003517          	auipc	a0,0x3
    80005272:	4b250513          	addi	a0,a0,1202 # 80008720 <syscalls+0x2e0>
    80005276:	ffffb097          	auipc	ra,0xffffb
    8000527a:	2d2080e7          	jalr	722(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000527e:	00003517          	auipc	a0,0x3
    80005282:	4b250513          	addi	a0,a0,1202 # 80008730 <syscalls+0x2f0>
    80005286:	ffffb097          	auipc	ra,0xffffb
    8000528a:	2c2080e7          	jalr	706(ra) # 80000548 <panic>
    return 0;
    8000528e:	84aa                	mv	s1,a0
    80005290:	b731                	j	8000519c <create+0x72>

0000000080005292 <sys_dup>:
{
    80005292:	7179                	addi	sp,sp,-48
    80005294:	f406                	sd	ra,40(sp)
    80005296:	f022                	sd	s0,32(sp)
    80005298:	ec26                	sd	s1,24(sp)
    8000529a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000529c:	fd840613          	addi	a2,s0,-40
    800052a0:	4581                	li	a1,0
    800052a2:	4501                	li	a0,0
    800052a4:	00000097          	auipc	ra,0x0
    800052a8:	ddc080e7          	jalr	-548(ra) # 80005080 <argfd>
    return -1;
    800052ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052ae:	02054363          	bltz	a0,800052d4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052b2:	fd843503          	ld	a0,-40(s0)
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	e32080e7          	jalr	-462(ra) # 800050e8 <fdalloc>
    800052be:	84aa                	mv	s1,a0
    return -1;
    800052c0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052c2:	00054963          	bltz	a0,800052d4 <sys_dup+0x42>
  filedup(f);
    800052c6:	fd843503          	ld	a0,-40(s0)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	32a080e7          	jalr	810(ra) # 800045f4 <filedup>
  return fd;
    800052d2:	87a6                	mv	a5,s1
}
    800052d4:	853e                	mv	a0,a5
    800052d6:	70a2                	ld	ra,40(sp)
    800052d8:	7402                	ld	s0,32(sp)
    800052da:	64e2                	ld	s1,24(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_read>:
{
    800052e0:	7179                	addi	sp,sp,-48
    800052e2:	f406                	sd	ra,40(sp)
    800052e4:	f022                	sd	s0,32(sp)
    800052e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e8:	fe840613          	addi	a2,s0,-24
    800052ec:	4581                	li	a1,0
    800052ee:	4501                	li	a0,0
    800052f0:	00000097          	auipc	ra,0x0
    800052f4:	d90080e7          	jalr	-624(ra) # 80005080 <argfd>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	04054163          	bltz	a0,8000533c <sys_read+0x5c>
    800052fe:	fe440593          	addi	a1,s0,-28
    80005302:	4509                	li	a0,2
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	8ac080e7          	jalr	-1876(ra) # 80002bb0 <argint>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	02054763          	bltz	a0,8000533c <sys_read+0x5c>
    80005312:	fd840593          	addi	a1,s0,-40
    80005316:	4505                	li	a0,1
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	8ba080e7          	jalr	-1862(ra) # 80002bd2 <argaddr>
    return -1;
    80005320:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005322:	00054d63          	bltz	a0,8000533c <sys_read+0x5c>
  return fileread(f, p, n);
    80005326:	fe442603          	lw	a2,-28(s0)
    8000532a:	fd843583          	ld	a1,-40(s0)
    8000532e:	fe843503          	ld	a0,-24(s0)
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	44e080e7          	jalr	1102(ra) # 80004780 <fileread>
    8000533a:	87aa                	mv	a5,a0
}
    8000533c:	853e                	mv	a0,a5
    8000533e:	70a2                	ld	ra,40(sp)
    80005340:	7402                	ld	s0,32(sp)
    80005342:	6145                	addi	sp,sp,48
    80005344:	8082                	ret

0000000080005346 <sys_write>:
{
    80005346:	7179                	addi	sp,sp,-48
    80005348:	f406                	sd	ra,40(sp)
    8000534a:	f022                	sd	s0,32(sp)
    8000534c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534e:	fe840613          	addi	a2,s0,-24
    80005352:	4581                	li	a1,0
    80005354:	4501                	li	a0,0
    80005356:	00000097          	auipc	ra,0x0
    8000535a:	d2a080e7          	jalr	-726(ra) # 80005080 <argfd>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	04054163          	bltz	a0,800053a2 <sys_write+0x5c>
    80005364:	fe440593          	addi	a1,s0,-28
    80005368:	4509                	li	a0,2
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	846080e7          	jalr	-1978(ra) # 80002bb0 <argint>
    return -1;
    80005372:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005374:	02054763          	bltz	a0,800053a2 <sys_write+0x5c>
    80005378:	fd840593          	addi	a1,s0,-40
    8000537c:	4505                	li	a0,1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	854080e7          	jalr	-1964(ra) # 80002bd2 <argaddr>
    return -1;
    80005386:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005388:	00054d63          	bltz	a0,800053a2 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000538c:	fe442603          	lw	a2,-28(s0)
    80005390:	fd843583          	ld	a1,-40(s0)
    80005394:	fe843503          	ld	a0,-24(s0)
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	4aa080e7          	jalr	1194(ra) # 80004842 <filewrite>
    800053a0:	87aa                	mv	a5,a0
}
    800053a2:	853e                	mv	a0,a5
    800053a4:	70a2                	ld	ra,40(sp)
    800053a6:	7402                	ld	s0,32(sp)
    800053a8:	6145                	addi	sp,sp,48
    800053aa:	8082                	ret

00000000800053ac <sys_close>:
{
    800053ac:	1101                	addi	sp,sp,-32
    800053ae:	ec06                	sd	ra,24(sp)
    800053b0:	e822                	sd	s0,16(sp)
    800053b2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053b4:	fe040613          	addi	a2,s0,-32
    800053b8:	fec40593          	addi	a1,s0,-20
    800053bc:	4501                	li	a0,0
    800053be:	00000097          	auipc	ra,0x0
    800053c2:	cc2080e7          	jalr	-830(ra) # 80005080 <argfd>
    return -1;
    800053c6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053c8:	02054463          	bltz	a0,800053f0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053cc:	ffffc097          	auipc	ra,0xffffc
    800053d0:	67e080e7          	jalr	1662(ra) # 80001a4a <myproc>
    800053d4:	fec42783          	lw	a5,-20(s0)
    800053d8:	07e9                	addi	a5,a5,26
    800053da:	078e                	slli	a5,a5,0x3
    800053dc:	97aa                	add	a5,a5,a0
    800053de:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053e2:	fe043503          	ld	a0,-32(s0)
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	260080e7          	jalr	608(ra) # 80004646 <fileclose>
  return 0;
    800053ee:	4781                	li	a5,0
}
    800053f0:	853e                	mv	a0,a5
    800053f2:	60e2                	ld	ra,24(sp)
    800053f4:	6442                	ld	s0,16(sp)
    800053f6:	6105                	addi	sp,sp,32
    800053f8:	8082                	ret

00000000800053fa <sys_fstat>:
{
    800053fa:	1101                	addi	sp,sp,-32
    800053fc:	ec06                	sd	ra,24(sp)
    800053fe:	e822                	sd	s0,16(sp)
    80005400:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005402:	fe840613          	addi	a2,s0,-24
    80005406:	4581                	li	a1,0
    80005408:	4501                	li	a0,0
    8000540a:	00000097          	auipc	ra,0x0
    8000540e:	c76080e7          	jalr	-906(ra) # 80005080 <argfd>
    return -1;
    80005412:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005414:	02054563          	bltz	a0,8000543e <sys_fstat+0x44>
    80005418:	fe040593          	addi	a1,s0,-32
    8000541c:	4505                	li	a0,1
    8000541e:	ffffd097          	auipc	ra,0xffffd
    80005422:	7b4080e7          	jalr	1972(ra) # 80002bd2 <argaddr>
    return -1;
    80005426:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005428:	00054b63          	bltz	a0,8000543e <sys_fstat+0x44>
  return filestat(f, st);
    8000542c:	fe043583          	ld	a1,-32(s0)
    80005430:	fe843503          	ld	a0,-24(s0)
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	2da080e7          	jalr	730(ra) # 8000470e <filestat>
    8000543c:	87aa                	mv	a5,a0
}
    8000543e:	853e                	mv	a0,a5
    80005440:	60e2                	ld	ra,24(sp)
    80005442:	6442                	ld	s0,16(sp)
    80005444:	6105                	addi	sp,sp,32
    80005446:	8082                	ret

0000000080005448 <sys_link>:
{
    80005448:	7169                	addi	sp,sp,-304
    8000544a:	f606                	sd	ra,296(sp)
    8000544c:	f222                	sd	s0,288(sp)
    8000544e:	ee26                	sd	s1,280(sp)
    80005450:	ea4a                	sd	s2,272(sp)
    80005452:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005454:	08000613          	li	a2,128
    80005458:	ed040593          	addi	a1,s0,-304
    8000545c:	4501                	li	a0,0
    8000545e:	ffffd097          	auipc	ra,0xffffd
    80005462:	796080e7          	jalr	1942(ra) # 80002bf4 <argstr>
    return -1;
    80005466:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005468:	10054e63          	bltz	a0,80005584 <sys_link+0x13c>
    8000546c:	08000613          	li	a2,128
    80005470:	f5040593          	addi	a1,s0,-176
    80005474:	4505                	li	a0,1
    80005476:	ffffd097          	auipc	ra,0xffffd
    8000547a:	77e080e7          	jalr	1918(ra) # 80002bf4 <argstr>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005480:	10054263          	bltz	a0,80005584 <sys_link+0x13c>
  begin_op();
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	cf0080e7          	jalr	-784(ra) # 80004174 <begin_op>
  if((ip = namei(old)) == 0){
    8000548c:	ed040513          	addi	a0,s0,-304
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	ad8080e7          	jalr	-1320(ra) # 80003f68 <namei>
    80005498:	84aa                	mv	s1,a0
    8000549a:	c551                	beqz	a0,80005526 <sys_link+0xde>
  ilock(ip);
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	31c080e7          	jalr	796(ra) # 800037b8 <ilock>
  if(ip->type == T_DIR){
    800054a4:	04449703          	lh	a4,68(s1)
    800054a8:	4785                	li	a5,1
    800054aa:	08f70463          	beq	a4,a5,80005532 <sys_link+0xea>
  ip->nlink++;
    800054ae:	04a4d783          	lhu	a5,74(s1)
    800054b2:	2785                	addiw	a5,a5,1
    800054b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054b8:	8526                	mv	a0,s1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	234080e7          	jalr	564(ra) # 800036ee <iupdate>
  iunlock(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	3b6080e7          	jalr	950(ra) # 8000387a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054cc:	fd040593          	addi	a1,s0,-48
    800054d0:	f5040513          	addi	a0,s0,-176
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	ab2080e7          	jalr	-1358(ra) # 80003f86 <nameiparent>
    800054dc:	892a                	mv	s2,a0
    800054de:	c935                	beqz	a0,80005552 <sys_link+0x10a>
  ilock(dp);
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	2d8080e7          	jalr	728(ra) # 800037b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054e8:	00092703          	lw	a4,0(s2)
    800054ec:	409c                	lw	a5,0(s1)
    800054ee:	04f71d63          	bne	a4,a5,80005548 <sys_link+0x100>
    800054f2:	40d0                	lw	a2,4(s1)
    800054f4:	fd040593          	addi	a1,s0,-48
    800054f8:	854a                	mv	a0,s2
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	9ac080e7          	jalr	-1620(ra) # 80003ea6 <dirlink>
    80005502:	04054363          	bltz	a0,80005548 <sys_link+0x100>
  iunlockput(dp);
    80005506:	854a                	mv	a0,s2
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	512080e7          	jalr	1298(ra) # 80003a1a <iunlockput>
  iput(ip);
    80005510:	8526                	mv	a0,s1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	460080e7          	jalr	1120(ra) # 80003972 <iput>
  end_op();
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	cda080e7          	jalr	-806(ra) # 800041f4 <end_op>
  return 0;
    80005522:	4781                	li	a5,0
    80005524:	a085                	j	80005584 <sys_link+0x13c>
    end_op();
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	cce080e7          	jalr	-818(ra) # 800041f4 <end_op>
    return -1;
    8000552e:	57fd                	li	a5,-1
    80005530:	a891                	j	80005584 <sys_link+0x13c>
    iunlockput(ip);
    80005532:	8526                	mv	a0,s1
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	4e6080e7          	jalr	1254(ra) # 80003a1a <iunlockput>
    end_op();
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	cb8080e7          	jalr	-840(ra) # 800041f4 <end_op>
    return -1;
    80005544:	57fd                	li	a5,-1
    80005546:	a83d                	j	80005584 <sys_link+0x13c>
    iunlockput(dp);
    80005548:	854a                	mv	a0,s2
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	4d0080e7          	jalr	1232(ra) # 80003a1a <iunlockput>
  ilock(ip);
    80005552:	8526                	mv	a0,s1
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	264080e7          	jalr	612(ra) # 800037b8 <ilock>
  ip->nlink--;
    8000555c:	04a4d783          	lhu	a5,74(s1)
    80005560:	37fd                	addiw	a5,a5,-1
    80005562:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	186080e7          	jalr	390(ra) # 800036ee <iupdate>
  iunlockput(ip);
    80005570:	8526                	mv	a0,s1
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	4a8080e7          	jalr	1192(ra) # 80003a1a <iunlockput>
  end_op();
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	c7a080e7          	jalr	-902(ra) # 800041f4 <end_op>
  return -1;
    80005582:	57fd                	li	a5,-1
}
    80005584:	853e                	mv	a0,a5
    80005586:	70b2                	ld	ra,296(sp)
    80005588:	7412                	ld	s0,288(sp)
    8000558a:	64f2                	ld	s1,280(sp)
    8000558c:	6952                	ld	s2,272(sp)
    8000558e:	6155                	addi	sp,sp,304
    80005590:	8082                	ret

0000000080005592 <sys_unlink>:
{
    80005592:	7151                	addi	sp,sp,-240
    80005594:	f586                	sd	ra,232(sp)
    80005596:	f1a2                	sd	s0,224(sp)
    80005598:	eda6                	sd	s1,216(sp)
    8000559a:	e9ca                	sd	s2,208(sp)
    8000559c:	e5ce                	sd	s3,200(sp)
    8000559e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055a0:	08000613          	li	a2,128
    800055a4:	f3040593          	addi	a1,s0,-208
    800055a8:	4501                	li	a0,0
    800055aa:	ffffd097          	auipc	ra,0xffffd
    800055ae:	64a080e7          	jalr	1610(ra) # 80002bf4 <argstr>
    800055b2:	18054163          	bltz	a0,80005734 <sys_unlink+0x1a2>
  begin_op();
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	bbe080e7          	jalr	-1090(ra) # 80004174 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055be:	fb040593          	addi	a1,s0,-80
    800055c2:	f3040513          	addi	a0,s0,-208
    800055c6:	fffff097          	auipc	ra,0xfffff
    800055ca:	9c0080e7          	jalr	-1600(ra) # 80003f86 <nameiparent>
    800055ce:	84aa                	mv	s1,a0
    800055d0:	c979                	beqz	a0,800056a6 <sys_unlink+0x114>
  ilock(dp);
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	1e6080e7          	jalr	486(ra) # 800037b8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055da:	00003597          	auipc	a1,0x3
    800055de:	13658593          	addi	a1,a1,310 # 80008710 <syscalls+0x2d0>
    800055e2:	fb040513          	addi	a0,s0,-80
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	696080e7          	jalr	1686(ra) # 80003c7c <namecmp>
    800055ee:	14050a63          	beqz	a0,80005742 <sys_unlink+0x1b0>
    800055f2:	00003597          	auipc	a1,0x3
    800055f6:	12658593          	addi	a1,a1,294 # 80008718 <syscalls+0x2d8>
    800055fa:	fb040513          	addi	a0,s0,-80
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	67e080e7          	jalr	1662(ra) # 80003c7c <namecmp>
    80005606:	12050e63          	beqz	a0,80005742 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000560a:	f2c40613          	addi	a2,s0,-212
    8000560e:	fb040593          	addi	a1,s0,-80
    80005612:	8526                	mv	a0,s1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	682080e7          	jalr	1666(ra) # 80003c96 <dirlookup>
    8000561c:	892a                	mv	s2,a0
    8000561e:	12050263          	beqz	a0,80005742 <sys_unlink+0x1b0>
  ilock(ip);
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	196080e7          	jalr	406(ra) # 800037b8 <ilock>
  if(ip->nlink < 1)
    8000562a:	04a91783          	lh	a5,74(s2)
    8000562e:	08f05263          	blez	a5,800056b2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005632:	04491703          	lh	a4,68(s2)
    80005636:	4785                	li	a5,1
    80005638:	08f70563          	beq	a4,a5,800056c2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000563c:	4641                	li	a2,16
    8000563e:	4581                	li	a1,0
    80005640:	fc040513          	addi	a0,s0,-64
    80005644:	ffffb097          	auipc	ra,0xffffb
    80005648:	734080e7          	jalr	1844(ra) # 80000d78 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000564c:	4741                	li	a4,16
    8000564e:	f2c42683          	lw	a3,-212(s0)
    80005652:	fc040613          	addi	a2,s0,-64
    80005656:	4581                	li	a1,0
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	508080e7          	jalr	1288(ra) # 80003b62 <writei>
    80005662:	47c1                	li	a5,16
    80005664:	0af51563          	bne	a0,a5,8000570e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005668:	04491703          	lh	a4,68(s2)
    8000566c:	4785                	li	a5,1
    8000566e:	0af70863          	beq	a4,a5,8000571e <sys_unlink+0x18c>
  iunlockput(dp);
    80005672:	8526                	mv	a0,s1
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	3a6080e7          	jalr	934(ra) # 80003a1a <iunlockput>
  ip->nlink--;
    8000567c:	04a95783          	lhu	a5,74(s2)
    80005680:	37fd                	addiw	a5,a5,-1
    80005682:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005686:	854a                	mv	a0,s2
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	066080e7          	jalr	102(ra) # 800036ee <iupdate>
  iunlockput(ip);
    80005690:	854a                	mv	a0,s2
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	388080e7          	jalr	904(ra) # 80003a1a <iunlockput>
  end_op();
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	b5a080e7          	jalr	-1190(ra) # 800041f4 <end_op>
  return 0;
    800056a2:	4501                	li	a0,0
    800056a4:	a84d                	j	80005756 <sys_unlink+0x1c4>
    end_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	b4e080e7          	jalr	-1202(ra) # 800041f4 <end_op>
    return -1;
    800056ae:	557d                	li	a0,-1
    800056b0:	a05d                	j	80005756 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056b2:	00003517          	auipc	a0,0x3
    800056b6:	08e50513          	addi	a0,a0,142 # 80008740 <syscalls+0x300>
    800056ba:	ffffb097          	auipc	ra,0xffffb
    800056be:	e8e080e7          	jalr	-370(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c2:	04c92703          	lw	a4,76(s2)
    800056c6:	02000793          	li	a5,32
    800056ca:	f6e7f9e3          	bgeu	a5,a4,8000563c <sys_unlink+0xaa>
    800056ce:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d2:	4741                	li	a4,16
    800056d4:	86ce                	mv	a3,s3
    800056d6:	f1840613          	addi	a2,s0,-232
    800056da:	4581                	li	a1,0
    800056dc:	854a                	mv	a0,s2
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	38e080e7          	jalr	910(ra) # 80003a6c <readi>
    800056e6:	47c1                	li	a5,16
    800056e8:	00f51b63          	bne	a0,a5,800056fe <sys_unlink+0x16c>
    if(de.inum != 0)
    800056ec:	f1845783          	lhu	a5,-232(s0)
    800056f0:	e7a1                	bnez	a5,80005738 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f2:	29c1                	addiw	s3,s3,16
    800056f4:	04c92783          	lw	a5,76(s2)
    800056f8:	fcf9ede3          	bltu	s3,a5,800056d2 <sys_unlink+0x140>
    800056fc:	b781                	j	8000563c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056fe:	00003517          	auipc	a0,0x3
    80005702:	05a50513          	addi	a0,a0,90 # 80008758 <syscalls+0x318>
    80005706:	ffffb097          	auipc	ra,0xffffb
    8000570a:	e42080e7          	jalr	-446(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000570e:	00003517          	auipc	a0,0x3
    80005712:	06250513          	addi	a0,a0,98 # 80008770 <syscalls+0x330>
    80005716:	ffffb097          	auipc	ra,0xffffb
    8000571a:	e32080e7          	jalr	-462(ra) # 80000548 <panic>
    dp->nlink--;
    8000571e:	04a4d783          	lhu	a5,74(s1)
    80005722:	37fd                	addiw	a5,a5,-1
    80005724:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	fc4080e7          	jalr	-60(ra) # 800036ee <iupdate>
    80005732:	b781                	j	80005672 <sys_unlink+0xe0>
    return -1;
    80005734:	557d                	li	a0,-1
    80005736:	a005                	j	80005756 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005738:	854a                	mv	a0,s2
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	2e0080e7          	jalr	736(ra) # 80003a1a <iunlockput>
  iunlockput(dp);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	2d6080e7          	jalr	726(ra) # 80003a1a <iunlockput>
  end_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	aa8080e7          	jalr	-1368(ra) # 800041f4 <end_op>
  return -1;
    80005754:	557d                	li	a0,-1
}
    80005756:	70ae                	ld	ra,232(sp)
    80005758:	740e                	ld	s0,224(sp)
    8000575a:	64ee                	ld	s1,216(sp)
    8000575c:	694e                	ld	s2,208(sp)
    8000575e:	69ae                	ld	s3,200(sp)
    80005760:	616d                	addi	sp,sp,240
    80005762:	8082                	ret

0000000080005764 <sys_open>:

uint64
sys_open(void)
{
    80005764:	7131                	addi	sp,sp,-192
    80005766:	fd06                	sd	ra,184(sp)
    80005768:	f922                	sd	s0,176(sp)
    8000576a:	f526                	sd	s1,168(sp)
    8000576c:	f14a                	sd	s2,160(sp)
    8000576e:	ed4e                	sd	s3,152(sp)
    80005770:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005772:	08000613          	li	a2,128
    80005776:	f5040593          	addi	a1,s0,-176
    8000577a:	4501                	li	a0,0
    8000577c:	ffffd097          	auipc	ra,0xffffd
    80005780:	478080e7          	jalr	1144(ra) # 80002bf4 <argstr>
    return -1;
    80005784:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005786:	0c054163          	bltz	a0,80005848 <sys_open+0xe4>
    8000578a:	f4c40593          	addi	a1,s0,-180
    8000578e:	4505                	li	a0,1
    80005790:	ffffd097          	auipc	ra,0xffffd
    80005794:	420080e7          	jalr	1056(ra) # 80002bb0 <argint>
    80005798:	0a054863          	bltz	a0,80005848 <sys_open+0xe4>

  begin_op();
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	9d8080e7          	jalr	-1576(ra) # 80004174 <begin_op>

  if(omode & O_CREATE){
    800057a4:	f4c42783          	lw	a5,-180(s0)
    800057a8:	2007f793          	andi	a5,a5,512
    800057ac:	cbdd                	beqz	a5,80005862 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057ae:	4681                	li	a3,0
    800057b0:	4601                	li	a2,0
    800057b2:	4589                	li	a1,2
    800057b4:	f5040513          	addi	a0,s0,-176
    800057b8:	00000097          	auipc	ra,0x0
    800057bc:	972080e7          	jalr	-1678(ra) # 8000512a <create>
    800057c0:	892a                	mv	s2,a0
    if(ip == 0){
    800057c2:	c959                	beqz	a0,80005858 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057c4:	04491703          	lh	a4,68(s2)
    800057c8:	478d                	li	a5,3
    800057ca:	00f71763          	bne	a4,a5,800057d8 <sys_open+0x74>
    800057ce:	04695703          	lhu	a4,70(s2)
    800057d2:	47a5                	li	a5,9
    800057d4:	0ce7ec63          	bltu	a5,a4,800058ac <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	db2080e7          	jalr	-590(ra) # 8000458a <filealloc>
    800057e0:	89aa                	mv	s3,a0
    800057e2:	10050263          	beqz	a0,800058e6 <sys_open+0x182>
    800057e6:	00000097          	auipc	ra,0x0
    800057ea:	902080e7          	jalr	-1790(ra) # 800050e8 <fdalloc>
    800057ee:	84aa                	mv	s1,a0
    800057f0:	0e054663          	bltz	a0,800058dc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057f4:	04491703          	lh	a4,68(s2)
    800057f8:	478d                	li	a5,3
    800057fa:	0cf70463          	beq	a4,a5,800058c2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057fe:	4789                	li	a5,2
    80005800:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005804:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005808:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000580c:	f4c42783          	lw	a5,-180(s0)
    80005810:	0017c713          	xori	a4,a5,1
    80005814:	8b05                	andi	a4,a4,1
    80005816:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000581a:	0037f713          	andi	a4,a5,3
    8000581e:	00e03733          	snez	a4,a4
    80005822:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005826:	4007f793          	andi	a5,a5,1024
    8000582a:	c791                	beqz	a5,80005836 <sys_open+0xd2>
    8000582c:	04491703          	lh	a4,68(s2)
    80005830:	4789                	li	a5,2
    80005832:	08f70f63          	beq	a4,a5,800058d0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005836:	854a                	mv	a0,s2
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	042080e7          	jalr	66(ra) # 8000387a <iunlock>
  end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	9b4080e7          	jalr	-1612(ra) # 800041f4 <end_op>

  return fd;
}
    80005848:	8526                	mv	a0,s1
    8000584a:	70ea                	ld	ra,184(sp)
    8000584c:	744a                	ld	s0,176(sp)
    8000584e:	74aa                	ld	s1,168(sp)
    80005850:	790a                	ld	s2,160(sp)
    80005852:	69ea                	ld	s3,152(sp)
    80005854:	6129                	addi	sp,sp,192
    80005856:	8082                	ret
      end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	99c080e7          	jalr	-1636(ra) # 800041f4 <end_op>
      return -1;
    80005860:	b7e5                	j	80005848 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005862:	f5040513          	addi	a0,s0,-176
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	702080e7          	jalr	1794(ra) # 80003f68 <namei>
    8000586e:	892a                	mv	s2,a0
    80005870:	c905                	beqz	a0,800058a0 <sys_open+0x13c>
    ilock(ip);
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	f46080e7          	jalr	-186(ra) # 800037b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000587a:	04491703          	lh	a4,68(s2)
    8000587e:	4785                	li	a5,1
    80005880:	f4f712e3          	bne	a4,a5,800057c4 <sys_open+0x60>
    80005884:	f4c42783          	lw	a5,-180(s0)
    80005888:	dba1                	beqz	a5,800057d8 <sys_open+0x74>
      iunlockput(ip);
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	18e080e7          	jalr	398(ra) # 80003a1a <iunlockput>
      end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	960080e7          	jalr	-1696(ra) # 800041f4 <end_op>
      return -1;
    8000589c:	54fd                	li	s1,-1
    8000589e:	b76d                	j	80005848 <sys_open+0xe4>
      end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	954080e7          	jalr	-1708(ra) # 800041f4 <end_op>
      return -1;
    800058a8:	54fd                	li	s1,-1
    800058aa:	bf79                	j	80005848 <sys_open+0xe4>
    iunlockput(ip);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	16c080e7          	jalr	364(ra) # 80003a1a <iunlockput>
    end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	93e080e7          	jalr	-1730(ra) # 800041f4 <end_op>
    return -1;
    800058be:	54fd                	li	s1,-1
    800058c0:	b761                	j	80005848 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058c2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058c6:	04691783          	lh	a5,70(s2)
    800058ca:	02f99223          	sh	a5,36(s3)
    800058ce:	bf2d                	j	80005808 <sys_open+0xa4>
    itrunc(ip);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	ff4080e7          	jalr	-12(ra) # 800038c6 <itrunc>
    800058da:	bfb1                	j	80005836 <sys_open+0xd2>
      fileclose(f);
    800058dc:	854e                	mv	a0,s3
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	d68080e7          	jalr	-664(ra) # 80004646 <fileclose>
    iunlockput(ip);
    800058e6:	854a                	mv	a0,s2
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	132080e7          	jalr	306(ra) # 80003a1a <iunlockput>
    end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	904080e7          	jalr	-1788(ra) # 800041f4 <end_op>
    return -1;
    800058f8:	54fd                	li	s1,-1
    800058fa:	b7b9                	j	80005848 <sys_open+0xe4>

00000000800058fc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058fc:	7175                	addi	sp,sp,-144
    800058fe:	e506                	sd	ra,136(sp)
    80005900:	e122                	sd	s0,128(sp)
    80005902:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	870080e7          	jalr	-1936(ra) # 80004174 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000590c:	08000613          	li	a2,128
    80005910:	f7040593          	addi	a1,s0,-144
    80005914:	4501                	li	a0,0
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	2de080e7          	jalr	734(ra) # 80002bf4 <argstr>
    8000591e:	02054963          	bltz	a0,80005950 <sys_mkdir+0x54>
    80005922:	4681                	li	a3,0
    80005924:	4601                	li	a2,0
    80005926:	4585                	li	a1,1
    80005928:	f7040513          	addi	a0,s0,-144
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	7fe080e7          	jalr	2046(ra) # 8000512a <create>
    80005934:	cd11                	beqz	a0,80005950 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	0e4080e7          	jalr	228(ra) # 80003a1a <iunlockput>
  end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	8b6080e7          	jalr	-1866(ra) # 800041f4 <end_op>
  return 0;
    80005946:	4501                	li	a0,0
}
    80005948:	60aa                	ld	ra,136(sp)
    8000594a:	640a                	ld	s0,128(sp)
    8000594c:	6149                	addi	sp,sp,144
    8000594e:	8082                	ret
    end_op();
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	8a4080e7          	jalr	-1884(ra) # 800041f4 <end_op>
    return -1;
    80005958:	557d                	li	a0,-1
    8000595a:	b7fd                	j	80005948 <sys_mkdir+0x4c>

000000008000595c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000595c:	7135                	addi	sp,sp,-160
    8000595e:	ed06                	sd	ra,152(sp)
    80005960:	e922                	sd	s0,144(sp)
    80005962:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	810080e7          	jalr	-2032(ra) # 80004174 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000596c:	08000613          	li	a2,128
    80005970:	f7040593          	addi	a1,s0,-144
    80005974:	4501                	li	a0,0
    80005976:	ffffd097          	auipc	ra,0xffffd
    8000597a:	27e080e7          	jalr	638(ra) # 80002bf4 <argstr>
    8000597e:	04054a63          	bltz	a0,800059d2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005982:	f6c40593          	addi	a1,s0,-148
    80005986:	4505                	li	a0,1
    80005988:	ffffd097          	auipc	ra,0xffffd
    8000598c:	228080e7          	jalr	552(ra) # 80002bb0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005990:	04054163          	bltz	a0,800059d2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005994:	f6840593          	addi	a1,s0,-152
    80005998:	4509                	li	a0,2
    8000599a:	ffffd097          	auipc	ra,0xffffd
    8000599e:	216080e7          	jalr	534(ra) # 80002bb0 <argint>
     argint(1, &major) < 0 ||
    800059a2:	02054863          	bltz	a0,800059d2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059a6:	f6841683          	lh	a3,-152(s0)
    800059aa:	f6c41603          	lh	a2,-148(s0)
    800059ae:	458d                	li	a1,3
    800059b0:	f7040513          	addi	a0,s0,-144
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	776080e7          	jalr	1910(ra) # 8000512a <create>
     argint(2, &minor) < 0 ||
    800059bc:	c919                	beqz	a0,800059d2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	05c080e7          	jalr	92(ra) # 80003a1a <iunlockput>
  end_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	82e080e7          	jalr	-2002(ra) # 800041f4 <end_op>
  return 0;
    800059ce:	4501                	li	a0,0
    800059d0:	a031                	j	800059dc <sys_mknod+0x80>
    end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	822080e7          	jalr	-2014(ra) # 800041f4 <end_op>
    return -1;
    800059da:	557d                	li	a0,-1
}
    800059dc:	60ea                	ld	ra,152(sp)
    800059de:	644a                	ld	s0,144(sp)
    800059e0:	610d                	addi	sp,sp,160
    800059e2:	8082                	ret

00000000800059e4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059e4:	7135                	addi	sp,sp,-160
    800059e6:	ed06                	sd	ra,152(sp)
    800059e8:	e922                	sd	s0,144(sp)
    800059ea:	e526                	sd	s1,136(sp)
    800059ec:	e14a                	sd	s2,128(sp)
    800059ee:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059f0:	ffffc097          	auipc	ra,0xffffc
    800059f4:	05a080e7          	jalr	90(ra) # 80001a4a <myproc>
    800059f8:	892a                	mv	s2,a0
  
  begin_op();
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	77a080e7          	jalr	1914(ra) # 80004174 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a02:	08000613          	li	a2,128
    80005a06:	f6040593          	addi	a1,s0,-160
    80005a0a:	4501                	li	a0,0
    80005a0c:	ffffd097          	auipc	ra,0xffffd
    80005a10:	1e8080e7          	jalr	488(ra) # 80002bf4 <argstr>
    80005a14:	04054b63          	bltz	a0,80005a6a <sys_chdir+0x86>
    80005a18:	f6040513          	addi	a0,s0,-160
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	54c080e7          	jalr	1356(ra) # 80003f68 <namei>
    80005a24:	84aa                	mv	s1,a0
    80005a26:	c131                	beqz	a0,80005a6a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	d90080e7          	jalr	-624(ra) # 800037b8 <ilock>
  if(ip->type != T_DIR){
    80005a30:	04449703          	lh	a4,68(s1)
    80005a34:	4785                	li	a5,1
    80005a36:	04f71063          	bne	a4,a5,80005a76 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	e3e080e7          	jalr	-450(ra) # 8000387a <iunlock>
  iput(p->cwd);
    80005a44:	15093503          	ld	a0,336(s2)
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	f2a080e7          	jalr	-214(ra) # 80003972 <iput>
  end_op();
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	7a4080e7          	jalr	1956(ra) # 800041f4 <end_op>
  p->cwd = ip;
    80005a58:	14993823          	sd	s1,336(s2)
  return 0;
    80005a5c:	4501                	li	a0,0
}
    80005a5e:	60ea                	ld	ra,152(sp)
    80005a60:	644a                	ld	s0,144(sp)
    80005a62:	64aa                	ld	s1,136(sp)
    80005a64:	690a                	ld	s2,128(sp)
    80005a66:	610d                	addi	sp,sp,160
    80005a68:	8082                	ret
    end_op();
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	78a080e7          	jalr	1930(ra) # 800041f4 <end_op>
    return -1;
    80005a72:	557d                	li	a0,-1
    80005a74:	b7ed                	j	80005a5e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a76:	8526                	mv	a0,s1
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	fa2080e7          	jalr	-94(ra) # 80003a1a <iunlockput>
    end_op();
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	774080e7          	jalr	1908(ra) # 800041f4 <end_op>
    return -1;
    80005a88:	557d                	li	a0,-1
    80005a8a:	bfd1                	j	80005a5e <sys_chdir+0x7a>

0000000080005a8c <sys_exec>:

uint64
sys_exec(void)
{
    80005a8c:	7145                	addi	sp,sp,-464
    80005a8e:	e786                	sd	ra,456(sp)
    80005a90:	e3a2                	sd	s0,448(sp)
    80005a92:	ff26                	sd	s1,440(sp)
    80005a94:	fb4a                	sd	s2,432(sp)
    80005a96:	f74e                	sd	s3,424(sp)
    80005a98:	f352                	sd	s4,416(sp)
    80005a9a:	ef56                	sd	s5,408(sp)
    80005a9c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a9e:	08000613          	li	a2,128
    80005aa2:	f4040593          	addi	a1,s0,-192
    80005aa6:	4501                	li	a0,0
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	14c080e7          	jalr	332(ra) # 80002bf4 <argstr>
    return -1;
    80005ab0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ab2:	0c054a63          	bltz	a0,80005b86 <sys_exec+0xfa>
    80005ab6:	e3840593          	addi	a1,s0,-456
    80005aba:	4505                	li	a0,1
    80005abc:	ffffd097          	auipc	ra,0xffffd
    80005ac0:	116080e7          	jalr	278(ra) # 80002bd2 <argaddr>
    80005ac4:	0c054163          	bltz	a0,80005b86 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ac8:	10000613          	li	a2,256
    80005acc:	4581                	li	a1,0
    80005ace:	e4040513          	addi	a0,s0,-448
    80005ad2:	ffffb097          	auipc	ra,0xffffb
    80005ad6:	2a6080e7          	jalr	678(ra) # 80000d78 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ada:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ade:	89a6                	mv	s3,s1
    80005ae0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ae2:	02000a13          	li	s4,32
    80005ae6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aea:	00391513          	slli	a0,s2,0x3
    80005aee:	e3040593          	addi	a1,s0,-464
    80005af2:	e3843783          	ld	a5,-456(s0)
    80005af6:	953e                	add	a0,a0,a5
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	01e080e7          	jalr	30(ra) # 80002b16 <fetchaddr>
    80005b00:	02054a63          	bltz	a0,80005b34 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b04:	e3043783          	ld	a5,-464(s0)
    80005b08:	c3b9                	beqz	a5,80005b4e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b0a:	ffffb097          	auipc	ra,0xffffb
    80005b0e:	082080e7          	jalr	130(ra) # 80000b8c <kalloc>
    80005b12:	85aa                	mv	a1,a0
    80005b14:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b18:	cd11                	beqz	a0,80005b34 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b1a:	6605                	lui	a2,0x1
    80005b1c:	e3043503          	ld	a0,-464(s0)
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	048080e7          	jalr	72(ra) # 80002b68 <fetchstr>
    80005b28:	00054663          	bltz	a0,80005b34 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b2c:	0905                	addi	s2,s2,1
    80005b2e:	09a1                	addi	s3,s3,8
    80005b30:	fb491be3          	bne	s2,s4,80005ae6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b34:	10048913          	addi	s2,s1,256
    80005b38:	6088                	ld	a0,0(s1)
    80005b3a:	c529                	beqz	a0,80005b84 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b3c:	ffffb097          	auipc	ra,0xffffb
    80005b40:	f54080e7          	jalr	-172(ra) # 80000a90 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b44:	04a1                	addi	s1,s1,8
    80005b46:	ff2499e3          	bne	s1,s2,80005b38 <sys_exec+0xac>
  return -1;
    80005b4a:	597d                	li	s2,-1
    80005b4c:	a82d                	j	80005b86 <sys_exec+0xfa>
      argv[i] = 0;
    80005b4e:	0a8e                	slli	s5,s5,0x3
    80005b50:	fc040793          	addi	a5,s0,-64
    80005b54:	9abe                	add	s5,s5,a5
    80005b56:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b5a:	e4040593          	addi	a1,s0,-448
    80005b5e:	f4040513          	addi	a0,s0,-192
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	194080e7          	jalr	404(ra) # 80004cf6 <exec>
    80005b6a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b6c:	10048993          	addi	s3,s1,256
    80005b70:	6088                	ld	a0,0(s1)
    80005b72:	c911                	beqz	a0,80005b86 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b74:	ffffb097          	auipc	ra,0xffffb
    80005b78:	f1c080e7          	jalr	-228(ra) # 80000a90 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b7c:	04a1                	addi	s1,s1,8
    80005b7e:	ff3499e3          	bne	s1,s3,80005b70 <sys_exec+0xe4>
    80005b82:	a011                	j	80005b86 <sys_exec+0xfa>
  return -1;
    80005b84:	597d                	li	s2,-1
}
    80005b86:	854a                	mv	a0,s2
    80005b88:	60be                	ld	ra,456(sp)
    80005b8a:	641e                	ld	s0,448(sp)
    80005b8c:	74fa                	ld	s1,440(sp)
    80005b8e:	795a                	ld	s2,432(sp)
    80005b90:	79ba                	ld	s3,424(sp)
    80005b92:	7a1a                	ld	s4,416(sp)
    80005b94:	6afa                	ld	s5,408(sp)
    80005b96:	6179                	addi	sp,sp,464
    80005b98:	8082                	ret

0000000080005b9a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b9a:	7139                	addi	sp,sp,-64
    80005b9c:	fc06                	sd	ra,56(sp)
    80005b9e:	f822                	sd	s0,48(sp)
    80005ba0:	f426                	sd	s1,40(sp)
    80005ba2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ba4:	ffffc097          	auipc	ra,0xffffc
    80005ba8:	ea6080e7          	jalr	-346(ra) # 80001a4a <myproc>
    80005bac:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bae:	fd840593          	addi	a1,s0,-40
    80005bb2:	4501                	li	a0,0
    80005bb4:	ffffd097          	auipc	ra,0xffffd
    80005bb8:	01e080e7          	jalr	30(ra) # 80002bd2 <argaddr>
    return -1;
    80005bbc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bbe:	0e054063          	bltz	a0,80005c9e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bc2:	fc840593          	addi	a1,s0,-56
    80005bc6:	fd040513          	addi	a0,s0,-48
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	dd2080e7          	jalr	-558(ra) # 8000499c <pipealloc>
    return -1;
    80005bd2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bd4:	0c054563          	bltz	a0,80005c9e <sys_pipe+0x104>
  fd0 = -1;
    80005bd8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bdc:	fd043503          	ld	a0,-48(s0)
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	508080e7          	jalr	1288(ra) # 800050e8 <fdalloc>
    80005be8:	fca42223          	sw	a0,-60(s0)
    80005bec:	08054c63          	bltz	a0,80005c84 <sys_pipe+0xea>
    80005bf0:	fc843503          	ld	a0,-56(s0)
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	4f4080e7          	jalr	1268(ra) # 800050e8 <fdalloc>
    80005bfc:	fca42023          	sw	a0,-64(s0)
    80005c00:	06054863          	bltz	a0,80005c70 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c04:	4691                	li	a3,4
    80005c06:	fc440613          	addi	a2,s0,-60
    80005c0a:	fd843583          	ld	a1,-40(s0)
    80005c0e:	68a8                	ld	a0,80(s1)
    80005c10:	ffffc097          	auipc	ra,0xffffc
    80005c14:	b2e080e7          	jalr	-1234(ra) # 8000173e <copyout>
    80005c18:	02054063          	bltz	a0,80005c38 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c1c:	4691                	li	a3,4
    80005c1e:	fc040613          	addi	a2,s0,-64
    80005c22:	fd843583          	ld	a1,-40(s0)
    80005c26:	0591                	addi	a1,a1,4
    80005c28:	68a8                	ld	a0,80(s1)
    80005c2a:	ffffc097          	auipc	ra,0xffffc
    80005c2e:	b14080e7          	jalr	-1260(ra) # 8000173e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c32:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c34:	06055563          	bgez	a0,80005c9e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c38:	fc442783          	lw	a5,-60(s0)
    80005c3c:	07e9                	addi	a5,a5,26
    80005c3e:	078e                	slli	a5,a5,0x3
    80005c40:	97a6                	add	a5,a5,s1
    80005c42:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c46:	fc042503          	lw	a0,-64(s0)
    80005c4a:	0569                	addi	a0,a0,26
    80005c4c:	050e                	slli	a0,a0,0x3
    80005c4e:	9526                	add	a0,a0,s1
    80005c50:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c54:	fd043503          	ld	a0,-48(s0)
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	9ee080e7          	jalr	-1554(ra) # 80004646 <fileclose>
    fileclose(wf);
    80005c60:	fc843503          	ld	a0,-56(s0)
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	9e2080e7          	jalr	-1566(ra) # 80004646 <fileclose>
    return -1;
    80005c6c:	57fd                	li	a5,-1
    80005c6e:	a805                	j	80005c9e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c70:	fc442783          	lw	a5,-60(s0)
    80005c74:	0007c863          	bltz	a5,80005c84 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c78:	01a78513          	addi	a0,a5,26
    80005c7c:	050e                	slli	a0,a0,0x3
    80005c7e:	9526                	add	a0,a0,s1
    80005c80:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c84:	fd043503          	ld	a0,-48(s0)
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	9be080e7          	jalr	-1602(ra) # 80004646 <fileclose>
    fileclose(wf);
    80005c90:	fc843503          	ld	a0,-56(s0)
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	9b2080e7          	jalr	-1614(ra) # 80004646 <fileclose>
    return -1;
    80005c9c:	57fd                	li	a5,-1
}
    80005c9e:	853e                	mv	a0,a5
    80005ca0:	70e2                	ld	ra,56(sp)
    80005ca2:	7442                	ld	s0,48(sp)
    80005ca4:	74a2                	ld	s1,40(sp)
    80005ca6:	6121                	addi	sp,sp,64
    80005ca8:	8082                	ret
    80005caa:	0000                	unimp
    80005cac:	0000                	unimp
	...

0000000080005cb0 <kernelvec>:
    80005cb0:	7111                	addi	sp,sp,-256
    80005cb2:	e006                	sd	ra,0(sp)
    80005cb4:	e40a                	sd	sp,8(sp)
    80005cb6:	e80e                	sd	gp,16(sp)
    80005cb8:	ec12                	sd	tp,24(sp)
    80005cba:	f016                	sd	t0,32(sp)
    80005cbc:	f41a                	sd	t1,40(sp)
    80005cbe:	f81e                	sd	t2,48(sp)
    80005cc0:	fc22                	sd	s0,56(sp)
    80005cc2:	e0a6                	sd	s1,64(sp)
    80005cc4:	e4aa                	sd	a0,72(sp)
    80005cc6:	e8ae                	sd	a1,80(sp)
    80005cc8:	ecb2                	sd	a2,88(sp)
    80005cca:	f0b6                	sd	a3,96(sp)
    80005ccc:	f4ba                	sd	a4,104(sp)
    80005cce:	f8be                	sd	a5,112(sp)
    80005cd0:	fcc2                	sd	a6,120(sp)
    80005cd2:	e146                	sd	a7,128(sp)
    80005cd4:	e54a                	sd	s2,136(sp)
    80005cd6:	e94e                	sd	s3,144(sp)
    80005cd8:	ed52                	sd	s4,152(sp)
    80005cda:	f156                	sd	s5,160(sp)
    80005cdc:	f55a                	sd	s6,168(sp)
    80005cde:	f95e                	sd	s7,176(sp)
    80005ce0:	fd62                	sd	s8,184(sp)
    80005ce2:	e1e6                	sd	s9,192(sp)
    80005ce4:	e5ea                	sd	s10,200(sp)
    80005ce6:	e9ee                	sd	s11,208(sp)
    80005ce8:	edf2                	sd	t3,216(sp)
    80005cea:	f1f6                	sd	t4,224(sp)
    80005cec:	f5fa                	sd	t5,232(sp)
    80005cee:	f9fe                	sd	t6,240(sp)
    80005cf0:	cf3fc0ef          	jal	ra,800029e2 <kerneltrap>
    80005cf4:	6082                	ld	ra,0(sp)
    80005cf6:	6122                	ld	sp,8(sp)
    80005cf8:	61c2                	ld	gp,16(sp)
    80005cfa:	7282                	ld	t0,32(sp)
    80005cfc:	7322                	ld	t1,40(sp)
    80005cfe:	73c2                	ld	t2,48(sp)
    80005d00:	7462                	ld	s0,56(sp)
    80005d02:	6486                	ld	s1,64(sp)
    80005d04:	6526                	ld	a0,72(sp)
    80005d06:	65c6                	ld	a1,80(sp)
    80005d08:	6666                	ld	a2,88(sp)
    80005d0a:	7686                	ld	a3,96(sp)
    80005d0c:	7726                	ld	a4,104(sp)
    80005d0e:	77c6                	ld	a5,112(sp)
    80005d10:	7866                	ld	a6,120(sp)
    80005d12:	688a                	ld	a7,128(sp)
    80005d14:	692a                	ld	s2,136(sp)
    80005d16:	69ca                	ld	s3,144(sp)
    80005d18:	6a6a                	ld	s4,152(sp)
    80005d1a:	7a8a                	ld	s5,160(sp)
    80005d1c:	7b2a                	ld	s6,168(sp)
    80005d1e:	7bca                	ld	s7,176(sp)
    80005d20:	7c6a                	ld	s8,184(sp)
    80005d22:	6c8e                	ld	s9,192(sp)
    80005d24:	6d2e                	ld	s10,200(sp)
    80005d26:	6dce                	ld	s11,208(sp)
    80005d28:	6e6e                	ld	t3,216(sp)
    80005d2a:	7e8e                	ld	t4,224(sp)
    80005d2c:	7f2e                	ld	t5,232(sp)
    80005d2e:	7fce                	ld	t6,240(sp)
    80005d30:	6111                	addi	sp,sp,256
    80005d32:	10200073          	sret
    80005d36:	00000013          	nop
    80005d3a:	00000013          	nop
    80005d3e:	0001                	nop

0000000080005d40 <timervec>:
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	e10c                	sd	a1,0(a0)
    80005d46:	e510                	sd	a2,8(a0)
    80005d48:	e914                	sd	a3,16(a0)
    80005d4a:	710c                	ld	a1,32(a0)
    80005d4c:	7510                	ld	a2,40(a0)
    80005d4e:	6194                	ld	a3,0(a1)
    80005d50:	96b2                	add	a3,a3,a2
    80005d52:	e194                	sd	a3,0(a1)
    80005d54:	4589                	li	a1,2
    80005d56:	14459073          	csrw	sip,a1
    80005d5a:	6914                	ld	a3,16(a0)
    80005d5c:	6510                	ld	a2,8(a0)
    80005d5e:	610c                	ld	a1,0(a0)
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	30200073          	mret
	...

0000000080005d6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d6a:	1141                	addi	sp,sp,-16
    80005d6c:	e422                	sd	s0,8(sp)
    80005d6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d70:	0c0007b7          	lui	a5,0xc000
    80005d74:	4705                	li	a4,1
    80005d76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d78:	c3d8                	sw	a4,4(a5)
}
    80005d7a:	6422                	ld	s0,8(sp)
    80005d7c:	0141                	addi	sp,sp,16
    80005d7e:	8082                	ret

0000000080005d80 <plicinithart>:

void
plicinithart(void)
{
    80005d80:	1141                	addi	sp,sp,-16
    80005d82:	e406                	sd	ra,8(sp)
    80005d84:	e022                	sd	s0,0(sp)
    80005d86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	c96080e7          	jalr	-874(ra) # 80001a1e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d90:	0085171b          	slliw	a4,a0,0x8
    80005d94:	0c0027b7          	lui	a5,0xc002
    80005d98:	97ba                	add	a5,a5,a4
    80005d9a:	40200713          	li	a4,1026
    80005d9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005da2:	00d5151b          	slliw	a0,a0,0xd
    80005da6:	0c2017b7          	lui	a5,0xc201
    80005daa:	953e                	add	a0,a0,a5
    80005dac:	00052023          	sw	zero,0(a0)
}
    80005db0:	60a2                	ld	ra,8(sp)
    80005db2:	6402                	ld	s0,0(sp)
    80005db4:	0141                	addi	sp,sp,16
    80005db6:	8082                	ret

0000000080005db8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005db8:	1141                	addi	sp,sp,-16
    80005dba:	e406                	sd	ra,8(sp)
    80005dbc:	e022                	sd	s0,0(sp)
    80005dbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	c5e080e7          	jalr	-930(ra) # 80001a1e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dc8:	00d5179b          	slliw	a5,a0,0xd
    80005dcc:	0c201537          	lui	a0,0xc201
    80005dd0:	953e                	add	a0,a0,a5
  return irq;
}
    80005dd2:	4148                	lw	a0,4(a0)
    80005dd4:	60a2                	ld	ra,8(sp)
    80005dd6:	6402                	ld	s0,0(sp)
    80005dd8:	0141                	addi	sp,sp,16
    80005dda:	8082                	ret

0000000080005ddc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ddc:	1101                	addi	sp,sp,-32
    80005dde:	ec06                	sd	ra,24(sp)
    80005de0:	e822                	sd	s0,16(sp)
    80005de2:	e426                	sd	s1,8(sp)
    80005de4:	1000                	addi	s0,sp,32
    80005de6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	c36080e7          	jalr	-970(ra) # 80001a1e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005df0:	00d5151b          	slliw	a0,a0,0xd
    80005df4:	0c2017b7          	lui	a5,0xc201
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	c3c4                	sw	s1,4(a5)
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	addi	sp,sp,32
    80005e04:	8082                	ret

0000000080005e06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e06:	1141                	addi	sp,sp,-16
    80005e08:	e406                	sd	ra,8(sp)
    80005e0a:	e022                	sd	s0,0(sp)
    80005e0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e0e:	479d                	li	a5,7
    80005e10:	04a7cc63          	blt	a5,a0,80005e68 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e14:	0001e797          	auipc	a5,0x1e
    80005e18:	1ec78793          	addi	a5,a5,492 # 80024000 <disk>
    80005e1c:	00a78733          	add	a4,a5,a0
    80005e20:	6789                	lui	a5,0x2
    80005e22:	97ba                	add	a5,a5,a4
    80005e24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e28:	eba1                	bnez	a5,80005e78 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e2a:	00451713          	slli	a4,a0,0x4
    80005e2e:	00020797          	auipc	a5,0x20
    80005e32:	1d27b783          	ld	a5,466(a5) # 80026000 <disk+0x2000>
    80005e36:	97ba                	add	a5,a5,a4
    80005e38:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e3c:	0001e797          	auipc	a5,0x1e
    80005e40:	1c478793          	addi	a5,a5,452 # 80024000 <disk>
    80005e44:	97aa                	add	a5,a5,a0
    80005e46:	6509                	lui	a0,0x2
    80005e48:	953e                	add	a0,a0,a5
    80005e4a:	4785                	li	a5,1
    80005e4c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e50:	00020517          	auipc	a0,0x20
    80005e54:	1c850513          	addi	a0,a0,456 # 80026018 <disk+0x2018>
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	5de080e7          	jalr	1502(ra) # 80002436 <wakeup>
}
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	addi	sp,sp,16
    80005e66:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	91850513          	addi	a0,a0,-1768 # 80008780 <syscalls+0x340>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6d8080e7          	jalr	1752(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	92050513          	addi	a0,a0,-1760 # 80008798 <syscalls+0x358>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6c8080e7          	jalr	1736(ra) # 80000548 <panic>

0000000080005e88 <virtio_disk_init>:
{
    80005e88:	1101                	addi	sp,sp,-32
    80005e8a:	ec06                	sd	ra,24(sp)
    80005e8c:	e822                	sd	s0,16(sp)
    80005e8e:	e426                	sd	s1,8(sp)
    80005e90:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e92:	00003597          	auipc	a1,0x3
    80005e96:	91e58593          	addi	a1,a1,-1762 # 800087b0 <syscalls+0x370>
    80005e9a:	00020517          	auipc	a0,0x20
    80005e9e:	20e50513          	addi	a0,a0,526 # 800260a8 <disk+0x20a8>
    80005ea2:	ffffb097          	auipc	ra,0xffffb
    80005ea6:	d4a080e7          	jalr	-694(ra) # 80000bec <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eaa:	100017b7          	lui	a5,0x10001
    80005eae:	4398                	lw	a4,0(a5)
    80005eb0:	2701                	sext.w	a4,a4
    80005eb2:	747277b7          	lui	a5,0x74727
    80005eb6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eba:	0ef71163          	bne	a4,a5,80005f9c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ebe:	100017b7          	lui	a5,0x10001
    80005ec2:	43dc                	lw	a5,4(a5)
    80005ec4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ec6:	4705                	li	a4,1
    80005ec8:	0ce79a63          	bne	a5,a4,80005f9c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ecc:	100017b7          	lui	a5,0x10001
    80005ed0:	479c                	lw	a5,8(a5)
    80005ed2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ed4:	4709                	li	a4,2
    80005ed6:	0ce79363          	bne	a5,a4,80005f9c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eda:	100017b7          	lui	a5,0x10001
    80005ede:	47d8                	lw	a4,12(a5)
    80005ee0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ee2:	554d47b7          	lui	a5,0x554d4
    80005ee6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eea:	0af71963          	bne	a4,a5,80005f9c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eee:	100017b7          	lui	a5,0x10001
    80005ef2:	4705                	li	a4,1
    80005ef4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef6:	470d                	li	a4,3
    80005ef8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005efa:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005efc:	c7ffe737          	lui	a4,0xc7ffe
    80005f00:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005f04:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f06:	2701                	sext.w	a4,a4
    80005f08:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0a:	472d                	li	a4,11
    80005f0c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0e:	473d                	li	a4,15
    80005f10:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f12:	6705                	lui	a4,0x1
    80005f14:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f16:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f1a:	5bdc                	lw	a5,52(a5)
    80005f1c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f1e:	c7d9                	beqz	a5,80005fac <virtio_disk_init+0x124>
  if(max < NUM)
    80005f20:	471d                	li	a4,7
    80005f22:	08f77d63          	bgeu	a4,a5,80005fbc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f26:	100014b7          	lui	s1,0x10001
    80005f2a:	47a1                	li	a5,8
    80005f2c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f2e:	6609                	lui	a2,0x2
    80005f30:	4581                	li	a1,0
    80005f32:	0001e517          	auipc	a0,0x1e
    80005f36:	0ce50513          	addi	a0,a0,206 # 80024000 <disk>
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	e3e080e7          	jalr	-450(ra) # 80000d78 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f42:	0001e717          	auipc	a4,0x1e
    80005f46:	0be70713          	addi	a4,a4,190 # 80024000 <disk>
    80005f4a:	00c75793          	srli	a5,a4,0xc
    80005f4e:	2781                	sext.w	a5,a5
    80005f50:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f52:	00020797          	auipc	a5,0x20
    80005f56:	0ae78793          	addi	a5,a5,174 # 80026000 <disk+0x2000>
    80005f5a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f5c:	0001e717          	auipc	a4,0x1e
    80005f60:	12470713          	addi	a4,a4,292 # 80024080 <disk+0x80>
    80005f64:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f66:	0001f717          	auipc	a4,0x1f
    80005f6a:	09a70713          	addi	a4,a4,154 # 80025000 <disk+0x1000>
    80005f6e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f70:	4705                	li	a4,1
    80005f72:	00e78c23          	sb	a4,24(a5)
    80005f76:	00e78ca3          	sb	a4,25(a5)
    80005f7a:	00e78d23          	sb	a4,26(a5)
    80005f7e:	00e78da3          	sb	a4,27(a5)
    80005f82:	00e78e23          	sb	a4,28(a5)
    80005f86:	00e78ea3          	sb	a4,29(a5)
    80005f8a:	00e78f23          	sb	a4,30(a5)
    80005f8e:	00e78fa3          	sb	a4,31(a5)
}
    80005f92:	60e2                	ld	ra,24(sp)
    80005f94:	6442                	ld	s0,16(sp)
    80005f96:	64a2                	ld	s1,8(sp)
    80005f98:	6105                	addi	sp,sp,32
    80005f9a:	8082                	ret
    panic("could not find virtio disk");
    80005f9c:	00003517          	auipc	a0,0x3
    80005fa0:	82450513          	addi	a0,a0,-2012 # 800087c0 <syscalls+0x380>
    80005fa4:	ffffa097          	auipc	ra,0xffffa
    80005fa8:	5a4080e7          	jalr	1444(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005fac:	00003517          	auipc	a0,0x3
    80005fb0:	83450513          	addi	a0,a0,-1996 # 800087e0 <syscalls+0x3a0>
    80005fb4:	ffffa097          	auipc	ra,0xffffa
    80005fb8:	594080e7          	jalr	1428(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005fbc:	00003517          	auipc	a0,0x3
    80005fc0:	84450513          	addi	a0,a0,-1980 # 80008800 <syscalls+0x3c0>
    80005fc4:	ffffa097          	auipc	ra,0xffffa
    80005fc8:	584080e7          	jalr	1412(ra) # 80000548 <panic>

0000000080005fcc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fcc:	7119                	addi	sp,sp,-128
    80005fce:	fc86                	sd	ra,120(sp)
    80005fd0:	f8a2                	sd	s0,112(sp)
    80005fd2:	f4a6                	sd	s1,104(sp)
    80005fd4:	f0ca                	sd	s2,96(sp)
    80005fd6:	ecce                	sd	s3,88(sp)
    80005fd8:	e8d2                	sd	s4,80(sp)
    80005fda:	e4d6                	sd	s5,72(sp)
    80005fdc:	e0da                	sd	s6,64(sp)
    80005fde:	fc5e                	sd	s7,56(sp)
    80005fe0:	f862                	sd	s8,48(sp)
    80005fe2:	f466                	sd	s9,40(sp)
    80005fe4:	f06a                	sd	s10,32(sp)
    80005fe6:	0100                	addi	s0,sp,128
    80005fe8:	892a                	mv	s2,a0
    80005fea:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fec:	00c52c83          	lw	s9,12(a0)
    80005ff0:	001c9c9b          	slliw	s9,s9,0x1
    80005ff4:	1c82                	slli	s9,s9,0x20
    80005ff6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ffa:	00020517          	auipc	a0,0x20
    80005ffe:	0ae50513          	addi	a0,a0,174 # 800260a8 <disk+0x20a8>
    80006002:	ffffb097          	auipc	ra,0xffffb
    80006006:	c7a080e7          	jalr	-902(ra) # 80000c7c <acquire>
  for(int i = 0; i < 3; i++){
    8000600a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000600c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000600e:	0001eb97          	auipc	s7,0x1e
    80006012:	ff2b8b93          	addi	s7,s7,-14 # 80024000 <disk>
    80006016:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006018:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000601a:	8a4e                	mv	s4,s3
    8000601c:	a051                	j	800060a0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000601e:	00fb86b3          	add	a3,s7,a5
    80006022:	96da                	add	a3,a3,s6
    80006024:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006028:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000602a:	0207c563          	bltz	a5,80006054 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000602e:	2485                	addiw	s1,s1,1
    80006030:	0711                	addi	a4,a4,4
    80006032:	23548d63          	beq	s1,s5,8000626c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006036:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006038:	00020697          	auipc	a3,0x20
    8000603c:	fe068693          	addi	a3,a3,-32 # 80026018 <disk+0x2018>
    80006040:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006042:	0006c583          	lbu	a1,0(a3)
    80006046:	fde1                	bnez	a1,8000601e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006048:	2785                	addiw	a5,a5,1
    8000604a:	0685                	addi	a3,a3,1
    8000604c:	ff879be3          	bne	a5,s8,80006042 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006050:	57fd                	li	a5,-1
    80006052:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006054:	02905a63          	blez	s1,80006088 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006058:	f9042503          	lw	a0,-112(s0)
    8000605c:	00000097          	auipc	ra,0x0
    80006060:	daa080e7          	jalr	-598(ra) # 80005e06 <free_desc>
      for(int j = 0; j < i; j++)
    80006064:	4785                	li	a5,1
    80006066:	0297d163          	bge	a5,s1,80006088 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000606a:	f9442503          	lw	a0,-108(s0)
    8000606e:	00000097          	auipc	ra,0x0
    80006072:	d98080e7          	jalr	-616(ra) # 80005e06 <free_desc>
      for(int j = 0; j < i; j++)
    80006076:	4789                	li	a5,2
    80006078:	0097d863          	bge	a5,s1,80006088 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000607c:	f9842503          	lw	a0,-104(s0)
    80006080:	00000097          	auipc	ra,0x0
    80006084:	d86080e7          	jalr	-634(ra) # 80005e06 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006088:	00020597          	auipc	a1,0x20
    8000608c:	02058593          	addi	a1,a1,32 # 800260a8 <disk+0x20a8>
    80006090:	00020517          	auipc	a0,0x20
    80006094:	f8850513          	addi	a0,a0,-120 # 80026018 <disk+0x2018>
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	218080e7          	jalr	536(ra) # 800022b0 <sleep>
  for(int i = 0; i < 3; i++){
    800060a0:	f9040713          	addi	a4,s0,-112
    800060a4:	84ce                	mv	s1,s3
    800060a6:	bf41                	j	80006036 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800060a8:	4785                	li	a5,1
    800060aa:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800060ae:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800060b2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060b6:	f9042983          	lw	s3,-112(s0)
    800060ba:	00499493          	slli	s1,s3,0x4
    800060be:	00020a17          	auipc	s4,0x20
    800060c2:	f42a0a13          	addi	s4,s4,-190 # 80026000 <disk+0x2000>
    800060c6:	000a3a83          	ld	s5,0(s4)
    800060ca:	9aa6                	add	s5,s5,s1
    800060cc:	f8040513          	addi	a0,s0,-128
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	07c080e7          	jalr	124(ra) # 8000114c <kvmpa>
    800060d8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060dc:	000a3783          	ld	a5,0(s4)
    800060e0:	97a6                	add	a5,a5,s1
    800060e2:	4741                	li	a4,16
    800060e4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060e6:	000a3783          	ld	a5,0(s4)
    800060ea:	97a6                	add	a5,a5,s1
    800060ec:	4705                	li	a4,1
    800060ee:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060f2:	f9442703          	lw	a4,-108(s0)
    800060f6:	000a3783          	ld	a5,0(s4)
    800060fa:	97a6                	add	a5,a5,s1
    800060fc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006100:	0712                	slli	a4,a4,0x4
    80006102:	000a3783          	ld	a5,0(s4)
    80006106:	97ba                	add	a5,a5,a4
    80006108:	05890693          	addi	a3,s2,88
    8000610c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000610e:	000a3783          	ld	a5,0(s4)
    80006112:	97ba                	add	a5,a5,a4
    80006114:	40000693          	li	a3,1024
    80006118:	c794                	sw	a3,8(a5)
  if(write)
    8000611a:	100d0a63          	beqz	s10,8000622e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000611e:	00020797          	auipc	a5,0x20
    80006122:	ee27b783          	ld	a5,-286(a5) # 80026000 <disk+0x2000>
    80006126:	97ba                	add	a5,a5,a4
    80006128:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000612c:	0001e517          	auipc	a0,0x1e
    80006130:	ed450513          	addi	a0,a0,-300 # 80024000 <disk>
    80006134:	00020797          	auipc	a5,0x20
    80006138:	ecc78793          	addi	a5,a5,-308 # 80026000 <disk+0x2000>
    8000613c:	6394                	ld	a3,0(a5)
    8000613e:	96ba                	add	a3,a3,a4
    80006140:	00c6d603          	lhu	a2,12(a3)
    80006144:	00166613          	ori	a2,a2,1
    80006148:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000614c:	f9842683          	lw	a3,-104(s0)
    80006150:	6390                	ld	a2,0(a5)
    80006152:	9732                	add	a4,a4,a2
    80006154:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006158:	20098613          	addi	a2,s3,512
    8000615c:	0612                	slli	a2,a2,0x4
    8000615e:	962a                	add	a2,a2,a0
    80006160:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006164:	00469713          	slli	a4,a3,0x4
    80006168:	6394                	ld	a3,0(a5)
    8000616a:	96ba                	add	a3,a3,a4
    8000616c:	6589                	lui	a1,0x2
    8000616e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006172:	94ae                	add	s1,s1,a1
    80006174:	94aa                	add	s1,s1,a0
    80006176:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006178:	6394                	ld	a3,0(a5)
    8000617a:	96ba                	add	a3,a3,a4
    8000617c:	4585                	li	a1,1
    8000617e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006180:	6394                	ld	a3,0(a5)
    80006182:	96ba                	add	a3,a3,a4
    80006184:	4509                	li	a0,2
    80006186:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000618a:	6394                	ld	a3,0(a5)
    8000618c:	9736                	add	a4,a4,a3
    8000618e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006192:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006196:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000619a:	6794                	ld	a3,8(a5)
    8000619c:	0026d703          	lhu	a4,2(a3)
    800061a0:	8b1d                	andi	a4,a4,7
    800061a2:	2709                	addiw	a4,a4,2
    800061a4:	0706                	slli	a4,a4,0x1
    800061a6:	9736                	add	a4,a4,a3
    800061a8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800061ac:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800061b0:	6798                	ld	a4,8(a5)
    800061b2:	00275783          	lhu	a5,2(a4)
    800061b6:	2785                	addiw	a5,a5,1
    800061b8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061bc:	100017b7          	lui	a5,0x10001
    800061c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061c4:	00492703          	lw	a4,4(s2)
    800061c8:	4785                	li	a5,1
    800061ca:	02f71163          	bne	a4,a5,800061ec <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800061ce:	00020997          	auipc	s3,0x20
    800061d2:	eda98993          	addi	s3,s3,-294 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061d8:	85ce                	mv	a1,s3
    800061da:	854a                	mv	a0,s2
    800061dc:	ffffc097          	auipc	ra,0xffffc
    800061e0:	0d4080e7          	jalr	212(ra) # 800022b0 <sleep>
  while(b->disk == 1) {
    800061e4:	00492783          	lw	a5,4(s2)
    800061e8:	fe9788e3          	beq	a5,s1,800061d8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061ec:	f9042483          	lw	s1,-112(s0)
    800061f0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800061f4:	00479713          	slli	a4,a5,0x4
    800061f8:	0001e797          	auipc	a5,0x1e
    800061fc:	e0878793          	addi	a5,a5,-504 # 80024000 <disk>
    80006200:	97ba                	add	a5,a5,a4
    80006202:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006206:	00020917          	auipc	s2,0x20
    8000620a:	dfa90913          	addi	s2,s2,-518 # 80026000 <disk+0x2000>
    free_desc(i);
    8000620e:	8526                	mv	a0,s1
    80006210:	00000097          	auipc	ra,0x0
    80006214:	bf6080e7          	jalr	-1034(ra) # 80005e06 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006218:	0492                	slli	s1,s1,0x4
    8000621a:	00093783          	ld	a5,0(s2)
    8000621e:	94be                	add	s1,s1,a5
    80006220:	00c4d783          	lhu	a5,12(s1)
    80006224:	8b85                	andi	a5,a5,1
    80006226:	cf89                	beqz	a5,80006240 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006228:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000622c:	b7cd                	j	8000620e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000622e:	00020797          	auipc	a5,0x20
    80006232:	dd27b783          	ld	a5,-558(a5) # 80026000 <disk+0x2000>
    80006236:	97ba                	add	a5,a5,a4
    80006238:	4689                	li	a3,2
    8000623a:	00d79623          	sh	a3,12(a5)
    8000623e:	b5fd                	j	8000612c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006240:	00020517          	auipc	a0,0x20
    80006244:	e6850513          	addi	a0,a0,-408 # 800260a8 <disk+0x20a8>
    80006248:	ffffb097          	auipc	ra,0xffffb
    8000624c:	ae8080e7          	jalr	-1304(ra) # 80000d30 <release>
}
    80006250:	70e6                	ld	ra,120(sp)
    80006252:	7446                	ld	s0,112(sp)
    80006254:	74a6                	ld	s1,104(sp)
    80006256:	7906                	ld	s2,96(sp)
    80006258:	69e6                	ld	s3,88(sp)
    8000625a:	6a46                	ld	s4,80(sp)
    8000625c:	6aa6                	ld	s5,72(sp)
    8000625e:	6b06                	ld	s6,64(sp)
    80006260:	7be2                	ld	s7,56(sp)
    80006262:	7c42                	ld	s8,48(sp)
    80006264:	7ca2                	ld	s9,40(sp)
    80006266:	7d02                	ld	s10,32(sp)
    80006268:	6109                	addi	sp,sp,128
    8000626a:	8082                	ret
  if(write)
    8000626c:	e20d1ee3          	bnez	s10,800060a8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006270:	f8042023          	sw	zero,-128(s0)
    80006274:	bd2d                	j	800060ae <virtio_disk_rw+0xe2>

0000000080006276 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006276:	1101                	addi	sp,sp,-32
    80006278:	ec06                	sd	ra,24(sp)
    8000627a:	e822                	sd	s0,16(sp)
    8000627c:	e426                	sd	s1,8(sp)
    8000627e:	e04a                	sd	s2,0(sp)
    80006280:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006282:	00020517          	auipc	a0,0x20
    80006286:	e2650513          	addi	a0,a0,-474 # 800260a8 <disk+0x20a8>
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	9f2080e7          	jalr	-1550(ra) # 80000c7c <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006292:	00020717          	auipc	a4,0x20
    80006296:	d6e70713          	addi	a4,a4,-658 # 80026000 <disk+0x2000>
    8000629a:	02075783          	lhu	a5,32(a4)
    8000629e:	6b18                	ld	a4,16(a4)
    800062a0:	00275683          	lhu	a3,2(a4)
    800062a4:	8ebd                	xor	a3,a3,a5
    800062a6:	8a9d                	andi	a3,a3,7
    800062a8:	cab9                	beqz	a3,800062fe <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062aa:	0001e917          	auipc	s2,0x1e
    800062ae:	d5690913          	addi	s2,s2,-682 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062b2:	00020497          	auipc	s1,0x20
    800062b6:	d4e48493          	addi	s1,s1,-690 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062ba:	078e                	slli	a5,a5,0x3
    800062bc:	97ba                	add	a5,a5,a4
    800062be:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062c0:	20078713          	addi	a4,a5,512
    800062c4:	0712                	slli	a4,a4,0x4
    800062c6:	974a                	add	a4,a4,s2
    800062c8:	03074703          	lbu	a4,48(a4)
    800062cc:	ef21                	bnez	a4,80006324 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062ce:	20078793          	addi	a5,a5,512
    800062d2:	0792                	slli	a5,a5,0x4
    800062d4:	97ca                	add	a5,a5,s2
    800062d6:	7798                	ld	a4,40(a5)
    800062d8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062dc:	7788                	ld	a0,40(a5)
    800062de:	ffffc097          	auipc	ra,0xffffc
    800062e2:	158080e7          	jalr	344(ra) # 80002436 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062e6:	0204d783          	lhu	a5,32(s1)
    800062ea:	2785                	addiw	a5,a5,1
    800062ec:	8b9d                	andi	a5,a5,7
    800062ee:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062f2:	6898                	ld	a4,16(s1)
    800062f4:	00275683          	lhu	a3,2(a4)
    800062f8:	8a9d                	andi	a3,a3,7
    800062fa:	fcf690e3          	bne	a3,a5,800062ba <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062fe:	10001737          	lui	a4,0x10001
    80006302:	533c                	lw	a5,96(a4)
    80006304:	8b8d                	andi	a5,a5,3
    80006306:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006308:	00020517          	auipc	a0,0x20
    8000630c:	da050513          	addi	a0,a0,-608 # 800260a8 <disk+0x20a8>
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	a20080e7          	jalr	-1504(ra) # 80000d30 <release>
}
    80006318:	60e2                	ld	ra,24(sp)
    8000631a:	6442                	ld	s0,16(sp)
    8000631c:	64a2                	ld	s1,8(sp)
    8000631e:	6902                	ld	s2,0(sp)
    80006320:	6105                	addi	sp,sp,32
    80006322:	8082                	ret
      panic("virtio_disk_intr status");
    80006324:	00002517          	auipc	a0,0x2
    80006328:	4fc50513          	addi	a0,a0,1276 # 80008820 <syscalls+0x3e0>
    8000632c:	ffffa097          	auipc	ra,0xffffa
    80006330:	21c080e7          	jalr	540(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
