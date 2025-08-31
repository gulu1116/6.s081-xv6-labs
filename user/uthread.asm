
user/_uthread:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <thread_init>:
struct thread *current_thread;
extern void thread_switch(uint64, uint64);
              
void 
thread_init(void)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
  // main() is thread 0, which will make the first invocation to
  // thread_schedule().  it needs a stack so that the first thread_switch() can
  // save thread 0's state.  thread_schedule() won't run the main thread ever
  // again, because its state is set to RUNNING, and thread_schedule() selects
  // a RUNNABLE thread.
  current_thread = &all_thread[0];
   6:	00001797          	auipc	a5,0x1
   a:	d3a78793          	addi	a5,a5,-710 # d40 <all_thread>
   e:	00001717          	auipc	a4,0x1
  12:	d2f73123          	sd	a5,-734(a4) # d30 <current_thread>
  current_thread->state = RUNNING;
  16:	4785                	li	a5,1
  18:	00003717          	auipc	a4,0x3
  1c:	d2f72423          	sw	a5,-728(a4) # 2d40 <__global_pointer$+0x182f>
}
  20:	6422                	ld	s0,8(sp)
  22:	0141                	addi	sp,sp,16
  24:	8082                	ret

0000000000000026 <thread_schedule>:

void 
thread_schedule(void)
{
  26:	1141                	addi	sp,sp,-16
  28:	e406                	sd	ra,8(sp)
  2a:	e022                	sd	s0,0(sp)
  2c:	0800                	addi	s0,sp,16
  struct thread *t, *next_thread;

  /* Find another runnable thread. */
  next_thread = 0;
  t = current_thread + 1;
  2e:	00001317          	auipc	t1,0x1
  32:	d0233303          	ld	t1,-766(t1) # d30 <current_thread>
  36:	6589                	lui	a1,0x2
  38:	07858593          	addi	a1,a1,120 # 2078 <__global_pointer$+0xb67>
  3c:	959a                	add	a1,a1,t1
  3e:	4791                	li	a5,4
  for(int i = 0; i < MAX_THREAD; i++){
    if(t >= all_thread + MAX_THREAD)
  40:	00009817          	auipc	a6,0x9
  44:	ee080813          	addi	a6,a6,-288 # 8f20 <base>
      t = all_thread;
    if(t->state == RUNNABLE) {
  48:	6689                	lui	a3,0x2
  4a:	4609                	li	a2,2
      next_thread = t;
      break;
    }
    t = t + 1;
  4c:	07868893          	addi	a7,a3,120 # 2078 <__global_pointer$+0xb67>
  50:	a809                	j	62 <thread_schedule+0x3c>
    if(t->state == RUNNABLE) {
  52:	00d58733          	add	a4,a1,a3
  56:	4318                	lw	a4,0(a4)
  58:	02c70963          	beq	a4,a2,8a <thread_schedule+0x64>
    t = t + 1;
  5c:	95c6                	add	a1,a1,a7
  for(int i = 0; i < MAX_THREAD; i++){
  5e:	37fd                	addiw	a5,a5,-1
  60:	cb81                	beqz	a5,70 <thread_schedule+0x4a>
    if(t >= all_thread + MAX_THREAD)
  62:	ff05e8e3          	bltu	a1,a6,52 <thread_schedule+0x2c>
      t = all_thread;
  66:	00001597          	auipc	a1,0x1
  6a:	cda58593          	addi	a1,a1,-806 # d40 <all_thread>
  6e:	b7d5                	j	52 <thread_schedule+0x2c>
  }

  if (next_thread == 0) {
    printf("thread_schedule: no runnable threads\n");
  70:	00001517          	auipc	a0,0x1
  74:	b8850513          	addi	a0,a0,-1144 # bf8 <malloc+0xea>
  78:	00001097          	auipc	ra,0x1
  7c:	9d8080e7          	jalr	-1576(ra) # a50 <printf>
    exit(-1);
  80:	557d                	li	a0,-1
  82:	00000097          	auipc	ra,0x0
  86:	656080e7          	jalr	1622(ra) # 6d8 <exit>
  }

  /* example variables assumed: struct thread *current_thread, *next_thread, *t; */
  if (current_thread != next_thread) {         /* switch threads?  */
  8a:	00b30e63          	beq	t1,a1,a6 <thread_schedule+0x80>
    struct thread *old = current_thread;
    struct thread *new = next_thread;

    current_thread = new; /* set global to new before switching */
  8e:	00001797          	auipc	a5,0x1
  92:	cab7b123          	sd	a1,-862(a5) # d30 <current_thread>
    /* call assembly switch: save old into old->context, restore new from new->context */
    thread_switch((uint64)&old->context, (uint64)&new->context);
  96:	6509                	lui	a0,0x2
  98:	0521                	addi	a0,a0,8
  9a:	95aa                	add	a1,a1,a0
  9c:	951a                	add	a0,a0,t1
  9e:	00000097          	auipc	ra,0x0
  a2:	35a080e7          	jalr	858(ra) # 3f8 <thread_switch>
  } else {
    next_thread = 0;
  }
}
  a6:	60a2                	ld	ra,8(sp)
  a8:	6402                	ld	s0,0(sp)
  aa:	0141                	addi	sp,sp,16
  ac:	8082                	ret

00000000000000ae <thread_create>:

void 
thread_create(void (*func)())
{
  ae:	1141                	addi	sp,sp,-16
  b0:	e422                	sd	s0,8(sp)
  b2:	0800                	addi	s0,sp,16
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  b4:	00001797          	auipc	a5,0x1
  b8:	c8c78793          	addi	a5,a5,-884 # d40 <all_thread>
    if (t->state == FREE) break;
  bc:	6689                	lui	a3,0x2
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  be:	07868593          	addi	a1,a3,120 # 2078 <__global_pointer$+0xb67>
  c2:	00009617          	auipc	a2,0x9
  c6:	e5e60613          	addi	a2,a2,-418 # 8f20 <base>
    if (t->state == FREE) break;
  ca:	00d78733          	add	a4,a5,a3
  ce:	4318                	lw	a4,0(a4)
  d0:	c701                	beqz	a4,d8 <thread_create+0x2a>
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  d2:	97ae                	add	a5,a5,a1
  d4:	fec79be3          	bne	a5,a2,ca <thread_create+0x1c>
  }
  t->state = RUNNABLE;
  d8:	6709                	lui	a4,0x2
  da:	97ba                	add	a5,a5,a4
  dc:	4709                	li	a4,2
  de:	c398                	sw	a4,0(a5)
  // YOUR CODE HERE

  /* Example inside thread_create after allocating a free thread t */
  t->context.ra = (uint64)func;                    // set return address to thread function
  e0:	e788                	sd	a0,8(a5)
  t->context.sp = (uint64)t->stack + STACK_SIZE;   // set stack pointer to top of thread's stack
  e2:	eb9c                	sd	a5,16(a5)
  /* You may zero other saved regs optionally */
  t->state = RUNNABLE;
}
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret

00000000000000ea <thread_yield>:

void 
thread_yield(void)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e406                	sd	ra,8(sp)
  ee:	e022                	sd	s0,0(sp)
  f0:	0800                	addi	s0,sp,16
  current_thread->state = RUNNABLE;
  f2:	00001797          	auipc	a5,0x1
  f6:	c3e7b783          	ld	a5,-962(a5) # d30 <current_thread>
  fa:	6709                	lui	a4,0x2
  fc:	97ba                	add	a5,a5,a4
  fe:	4709                	li	a4,2
 100:	c398                	sw	a4,0(a5)
  thread_schedule();
 102:	00000097          	auipc	ra,0x0
 106:	f24080e7          	jalr	-220(ra) # 26 <thread_schedule>
}
 10a:	60a2                	ld	ra,8(sp)
 10c:	6402                	ld	s0,0(sp)
 10e:	0141                	addi	sp,sp,16
 110:	8082                	ret

0000000000000112 <thread_a>:
volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
thread_a(void)
{
 112:	7179                	addi	sp,sp,-48
 114:	f406                	sd	ra,40(sp)
 116:	f022                	sd	s0,32(sp)
 118:	ec26                	sd	s1,24(sp)
 11a:	e84a                	sd	s2,16(sp)
 11c:	e44e                	sd	s3,8(sp)
 11e:	e052                	sd	s4,0(sp)
 120:	1800                	addi	s0,sp,48
  int i;
  printf("thread_a started\n");
 122:	00001517          	auipc	a0,0x1
 126:	afe50513          	addi	a0,a0,-1282 # c20 <malloc+0x112>
 12a:	00001097          	auipc	ra,0x1
 12e:	926080e7          	jalr	-1754(ra) # a50 <printf>
  a_started = 1;
 132:	4785                	li	a5,1
 134:	00001717          	auipc	a4,0x1
 138:	bef72c23          	sw	a5,-1032(a4) # d2c <a_started>
  while(b_started == 0 || c_started == 0)
 13c:	00001497          	auipc	s1,0x1
 140:	bec48493          	addi	s1,s1,-1044 # d28 <b_started>
 144:	00001917          	auipc	s2,0x1
 148:	be090913          	addi	s2,s2,-1056 # d24 <c_started>
 14c:	a029                	j	156 <thread_a+0x44>
    thread_yield();
 14e:	00000097          	auipc	ra,0x0
 152:	f9c080e7          	jalr	-100(ra) # ea <thread_yield>
  while(b_started == 0 || c_started == 0)
 156:	409c                	lw	a5,0(s1)
 158:	2781                	sext.w	a5,a5
 15a:	dbf5                	beqz	a5,14e <thread_a+0x3c>
 15c:	00092783          	lw	a5,0(s2)
 160:	2781                	sext.w	a5,a5
 162:	d7f5                	beqz	a5,14e <thread_a+0x3c>
  
  for (i = 0; i < 100; i++) {
 164:	4481                	li	s1,0
    printf("thread_a %d\n", i);
 166:	00001a17          	auipc	s4,0x1
 16a:	ad2a0a13          	addi	s4,s4,-1326 # c38 <malloc+0x12a>
    a_n += 1;
 16e:	00001917          	auipc	s2,0x1
 172:	bb290913          	addi	s2,s2,-1102 # d20 <a_n>
  for (i = 0; i < 100; i++) {
 176:	06400993          	li	s3,100
    printf("thread_a %d\n", i);
 17a:	85a6                	mv	a1,s1
 17c:	8552                	mv	a0,s4
 17e:	00001097          	auipc	ra,0x1
 182:	8d2080e7          	jalr	-1838(ra) # a50 <printf>
    a_n += 1;
 186:	00092783          	lw	a5,0(s2)
 18a:	2785                	addiw	a5,a5,1
 18c:	00f92023          	sw	a5,0(s2)
    thread_yield();
 190:	00000097          	auipc	ra,0x0
 194:	f5a080e7          	jalr	-166(ra) # ea <thread_yield>
  for (i = 0; i < 100; i++) {
 198:	2485                	addiw	s1,s1,1
 19a:	ff3490e3          	bne	s1,s3,17a <thread_a+0x68>
  }
  printf("thread_a: exit after %d\n", a_n);
 19e:	00001597          	auipc	a1,0x1
 1a2:	b825a583          	lw	a1,-1150(a1) # d20 <a_n>
 1a6:	00001517          	auipc	a0,0x1
 1aa:	aa250513          	addi	a0,a0,-1374 # c48 <malloc+0x13a>
 1ae:	00001097          	auipc	ra,0x1
 1b2:	8a2080e7          	jalr	-1886(ra) # a50 <printf>

  current_thread->state = FREE;
 1b6:	00001797          	auipc	a5,0x1
 1ba:	b7a7b783          	ld	a5,-1158(a5) # d30 <current_thread>
 1be:	6709                	lui	a4,0x2
 1c0:	97ba                	add	a5,a5,a4
 1c2:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 1c6:	00000097          	auipc	ra,0x0
 1ca:	e60080e7          	jalr	-416(ra) # 26 <thread_schedule>
}
 1ce:	70a2                	ld	ra,40(sp)
 1d0:	7402                	ld	s0,32(sp)
 1d2:	64e2                	ld	s1,24(sp)
 1d4:	6942                	ld	s2,16(sp)
 1d6:	69a2                	ld	s3,8(sp)
 1d8:	6a02                	ld	s4,0(sp)
 1da:	6145                	addi	sp,sp,48
 1dc:	8082                	ret

00000000000001de <thread_b>:

void 
thread_b(void)
{
 1de:	7179                	addi	sp,sp,-48
 1e0:	f406                	sd	ra,40(sp)
 1e2:	f022                	sd	s0,32(sp)
 1e4:	ec26                	sd	s1,24(sp)
 1e6:	e84a                	sd	s2,16(sp)
 1e8:	e44e                	sd	s3,8(sp)
 1ea:	e052                	sd	s4,0(sp)
 1ec:	1800                	addi	s0,sp,48
  int i;
  printf("thread_b started\n");
 1ee:	00001517          	auipc	a0,0x1
 1f2:	a7a50513          	addi	a0,a0,-1414 # c68 <malloc+0x15a>
 1f6:	00001097          	auipc	ra,0x1
 1fa:	85a080e7          	jalr	-1958(ra) # a50 <printf>
  b_started = 1;
 1fe:	4785                	li	a5,1
 200:	00001717          	auipc	a4,0x1
 204:	b2f72423          	sw	a5,-1240(a4) # d28 <b_started>
  while(a_started == 0 || c_started == 0)
 208:	00001497          	auipc	s1,0x1
 20c:	b2448493          	addi	s1,s1,-1244 # d2c <a_started>
 210:	00001917          	auipc	s2,0x1
 214:	b1490913          	addi	s2,s2,-1260 # d24 <c_started>
 218:	a029                	j	222 <thread_b+0x44>
    thread_yield();
 21a:	00000097          	auipc	ra,0x0
 21e:	ed0080e7          	jalr	-304(ra) # ea <thread_yield>
  while(a_started == 0 || c_started == 0)
 222:	409c                	lw	a5,0(s1)
 224:	2781                	sext.w	a5,a5
 226:	dbf5                	beqz	a5,21a <thread_b+0x3c>
 228:	00092783          	lw	a5,0(s2)
 22c:	2781                	sext.w	a5,a5
 22e:	d7f5                	beqz	a5,21a <thread_b+0x3c>
  
  for (i = 0; i < 100; i++) {
 230:	4481                	li	s1,0
    printf("thread_b %d\n", i);
 232:	00001a17          	auipc	s4,0x1
 236:	a4ea0a13          	addi	s4,s4,-1458 # c80 <malloc+0x172>
    b_n += 1;
 23a:	00001917          	auipc	s2,0x1
 23e:	ae290913          	addi	s2,s2,-1310 # d1c <b_n>
  for (i = 0; i < 100; i++) {
 242:	06400993          	li	s3,100
    printf("thread_b %d\n", i);
 246:	85a6                	mv	a1,s1
 248:	8552                	mv	a0,s4
 24a:	00001097          	auipc	ra,0x1
 24e:	806080e7          	jalr	-2042(ra) # a50 <printf>
    b_n += 1;
 252:	00092783          	lw	a5,0(s2)
 256:	2785                	addiw	a5,a5,1
 258:	00f92023          	sw	a5,0(s2)
    thread_yield();
 25c:	00000097          	auipc	ra,0x0
 260:	e8e080e7          	jalr	-370(ra) # ea <thread_yield>
  for (i = 0; i < 100; i++) {
 264:	2485                	addiw	s1,s1,1
 266:	ff3490e3          	bne	s1,s3,246 <thread_b+0x68>
  }
  printf("thread_b: exit after %d\n", b_n);
 26a:	00001597          	auipc	a1,0x1
 26e:	ab25a583          	lw	a1,-1358(a1) # d1c <b_n>
 272:	00001517          	auipc	a0,0x1
 276:	a1e50513          	addi	a0,a0,-1506 # c90 <malloc+0x182>
 27a:	00000097          	auipc	ra,0x0
 27e:	7d6080e7          	jalr	2006(ra) # a50 <printf>

  current_thread->state = FREE;
 282:	00001797          	auipc	a5,0x1
 286:	aae7b783          	ld	a5,-1362(a5) # d30 <current_thread>
 28a:	6709                	lui	a4,0x2
 28c:	97ba                	add	a5,a5,a4
 28e:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 292:	00000097          	auipc	ra,0x0
 296:	d94080e7          	jalr	-620(ra) # 26 <thread_schedule>
}
 29a:	70a2                	ld	ra,40(sp)
 29c:	7402                	ld	s0,32(sp)
 29e:	64e2                	ld	s1,24(sp)
 2a0:	6942                	ld	s2,16(sp)
 2a2:	69a2                	ld	s3,8(sp)
 2a4:	6a02                	ld	s4,0(sp)
 2a6:	6145                	addi	sp,sp,48
 2a8:	8082                	ret

00000000000002aa <thread_c>:

void 
thread_c(void)
{
 2aa:	7179                	addi	sp,sp,-48
 2ac:	f406                	sd	ra,40(sp)
 2ae:	f022                	sd	s0,32(sp)
 2b0:	ec26                	sd	s1,24(sp)
 2b2:	e84a                	sd	s2,16(sp)
 2b4:	e44e                	sd	s3,8(sp)
 2b6:	e052                	sd	s4,0(sp)
 2b8:	1800                	addi	s0,sp,48
  int i;
  printf("thread_c started\n");
 2ba:	00001517          	auipc	a0,0x1
 2be:	9f650513          	addi	a0,a0,-1546 # cb0 <malloc+0x1a2>
 2c2:	00000097          	auipc	ra,0x0
 2c6:	78e080e7          	jalr	1934(ra) # a50 <printf>
  c_started = 1;
 2ca:	4785                	li	a5,1
 2cc:	00001717          	auipc	a4,0x1
 2d0:	a4f72c23          	sw	a5,-1448(a4) # d24 <c_started>
  while(a_started == 0 || b_started == 0)
 2d4:	00001497          	auipc	s1,0x1
 2d8:	a5848493          	addi	s1,s1,-1448 # d2c <a_started>
 2dc:	00001917          	auipc	s2,0x1
 2e0:	a4c90913          	addi	s2,s2,-1460 # d28 <b_started>
 2e4:	a029                	j	2ee <thread_c+0x44>
    thread_yield();
 2e6:	00000097          	auipc	ra,0x0
 2ea:	e04080e7          	jalr	-508(ra) # ea <thread_yield>
  while(a_started == 0 || b_started == 0)
 2ee:	409c                	lw	a5,0(s1)
 2f0:	2781                	sext.w	a5,a5
 2f2:	dbf5                	beqz	a5,2e6 <thread_c+0x3c>
 2f4:	00092783          	lw	a5,0(s2)
 2f8:	2781                	sext.w	a5,a5
 2fa:	d7f5                	beqz	a5,2e6 <thread_c+0x3c>
  
  for (i = 0; i < 100; i++) {
 2fc:	4481                	li	s1,0
    printf("thread_c %d\n", i);
 2fe:	00001a17          	auipc	s4,0x1
 302:	9caa0a13          	addi	s4,s4,-1590 # cc8 <malloc+0x1ba>
    c_n += 1;
 306:	00001917          	auipc	s2,0x1
 30a:	a1290913          	addi	s2,s2,-1518 # d18 <c_n>
  for (i = 0; i < 100; i++) {
 30e:	06400993          	li	s3,100
    printf("thread_c %d\n", i);
 312:	85a6                	mv	a1,s1
 314:	8552                	mv	a0,s4
 316:	00000097          	auipc	ra,0x0
 31a:	73a080e7          	jalr	1850(ra) # a50 <printf>
    c_n += 1;
 31e:	00092783          	lw	a5,0(s2)
 322:	2785                	addiw	a5,a5,1
 324:	00f92023          	sw	a5,0(s2)
    thread_yield();
 328:	00000097          	auipc	ra,0x0
 32c:	dc2080e7          	jalr	-574(ra) # ea <thread_yield>
  for (i = 0; i < 100; i++) {
 330:	2485                	addiw	s1,s1,1
 332:	ff3490e3          	bne	s1,s3,312 <thread_c+0x68>
  }
  printf("thread_c: exit after %d\n", c_n);
 336:	00001597          	auipc	a1,0x1
 33a:	9e25a583          	lw	a1,-1566(a1) # d18 <c_n>
 33e:	00001517          	auipc	a0,0x1
 342:	99a50513          	addi	a0,a0,-1638 # cd8 <malloc+0x1ca>
 346:	00000097          	auipc	ra,0x0
 34a:	70a080e7          	jalr	1802(ra) # a50 <printf>

  current_thread->state = FREE;
 34e:	00001797          	auipc	a5,0x1
 352:	9e27b783          	ld	a5,-1566(a5) # d30 <current_thread>
 356:	6709                	lui	a4,0x2
 358:	97ba                	add	a5,a5,a4
 35a:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 35e:	00000097          	auipc	ra,0x0
 362:	cc8080e7          	jalr	-824(ra) # 26 <thread_schedule>
}
 366:	70a2                	ld	ra,40(sp)
 368:	7402                	ld	s0,32(sp)
 36a:	64e2                	ld	s1,24(sp)
 36c:	6942                	ld	s2,16(sp)
 36e:	69a2                	ld	s3,8(sp)
 370:	6a02                	ld	s4,0(sp)
 372:	6145                	addi	sp,sp,48
 374:	8082                	ret

0000000000000376 <main>:

int 
main(int argc, char *argv[]) 
{
 376:	1141                	addi	sp,sp,-16
 378:	e406                	sd	ra,8(sp)
 37a:	e022                	sd	s0,0(sp)
 37c:	0800                	addi	s0,sp,16
  a_started = b_started = c_started = 0;
 37e:	00001797          	auipc	a5,0x1
 382:	9a07a323          	sw	zero,-1626(a5) # d24 <c_started>
 386:	00001797          	auipc	a5,0x1
 38a:	9a07a123          	sw	zero,-1630(a5) # d28 <b_started>
 38e:	00001797          	auipc	a5,0x1
 392:	9807af23          	sw	zero,-1634(a5) # d2c <a_started>
  a_n = b_n = c_n = 0;
 396:	00001797          	auipc	a5,0x1
 39a:	9807a123          	sw	zero,-1662(a5) # d18 <c_n>
 39e:	00001797          	auipc	a5,0x1
 3a2:	9607af23          	sw	zero,-1666(a5) # d1c <b_n>
 3a6:	00001797          	auipc	a5,0x1
 3aa:	9607ad23          	sw	zero,-1670(a5) # d20 <a_n>
  thread_init();
 3ae:	00000097          	auipc	ra,0x0
 3b2:	c52080e7          	jalr	-942(ra) # 0 <thread_init>
  thread_create(thread_a);
 3b6:	00000517          	auipc	a0,0x0
 3ba:	d5c50513          	addi	a0,a0,-676 # 112 <thread_a>
 3be:	00000097          	auipc	ra,0x0
 3c2:	cf0080e7          	jalr	-784(ra) # ae <thread_create>
  thread_create(thread_b);
 3c6:	00000517          	auipc	a0,0x0
 3ca:	e1850513          	addi	a0,a0,-488 # 1de <thread_b>
 3ce:	00000097          	auipc	ra,0x0
 3d2:	ce0080e7          	jalr	-800(ra) # ae <thread_create>
  thread_create(thread_c);
 3d6:	00000517          	auipc	a0,0x0
 3da:	ed450513          	addi	a0,a0,-300 # 2aa <thread_c>
 3de:	00000097          	auipc	ra,0x0
 3e2:	cd0080e7          	jalr	-816(ra) # ae <thread_create>
  thread_schedule();
 3e6:	00000097          	auipc	ra,0x0
 3ea:	c40080e7          	jalr	-960(ra) # 26 <thread_schedule>
  exit(0);
 3ee:	4501                	li	a0,0
 3f0:	00000097          	auipc	ra,0x0
 3f4:	2e8080e7          	jalr	744(ra) # 6d8 <exit>

00000000000003f8 <thread_switch>:
 * then load ra, sp, s0..s11 from *a1, and return (ret) to new ra.
 */

thread_switch:
    /* save callee-saved regs + ra, sp into old context (at a0) */
    sd ra, 0(a0)
 3f8:	00153023          	sd	ra,0(a0)
    sd sp, 8(a0)
 3fc:	00253423          	sd	sp,8(a0)
    sd s0, 16(a0)
 400:	e900                	sd	s0,16(a0)
    sd s1, 24(a0)
 402:	ed04                	sd	s1,24(a0)
    sd s2, 32(a0)
 404:	03253023          	sd	s2,32(a0)
    sd s3, 40(a0)
 408:	03353423          	sd	s3,40(a0)
    sd s4, 48(a0)
 40c:	03453823          	sd	s4,48(a0)
    sd s5, 56(a0)
 410:	03553c23          	sd	s5,56(a0)
    sd s6, 64(a0)
 414:	05653023          	sd	s6,64(a0)
    sd s7, 72(a0)
 418:	05753423          	sd	s7,72(a0)
    sd s8, 80(a0)
 41c:	05853823          	sd	s8,80(a0)
    sd s9, 88(a0)
 420:	05953c23          	sd	s9,88(a0)
    sd s10, 96(a0)
 424:	07a53023          	sd	s10,96(a0)
    sd s11, 104(a0)
 428:	07b53423          	sd	s11,104(a0)

    /* restore registers from new context (at a1) */
    ld ra, 0(a1)
 42c:	0005b083          	ld	ra,0(a1)
    ld sp, 8(a1)
 430:	0085b103          	ld	sp,8(a1)
    ld s0, 16(a1)
 434:	6980                	ld	s0,16(a1)
    ld s1, 24(a1)
 436:	6d84                	ld	s1,24(a1)
    ld s2, 32(a1)
 438:	0205b903          	ld	s2,32(a1)
    ld s3, 40(a1)
 43c:	0285b983          	ld	s3,40(a1)
    ld s4, 48(a1)
 440:	0305ba03          	ld	s4,48(a1)
    ld s5, 56(a1)
 444:	0385ba83          	ld	s5,56(a1)
    ld s6, 64(a1)
 448:	0405bb03          	ld	s6,64(a1)
    ld s7, 72(a1)
 44c:	0485bb83          	ld	s7,72(a1)
    ld s8, 80(a1)
 450:	0505bc03          	ld	s8,80(a1)
    ld s9, 88(a1)
 454:	0585bc83          	ld	s9,88(a1)
    ld s10, 96(a1)
 458:	0605bd03          	ld	s10,96(a1)
    ld s11, 104(a1)
 45c:	0685bd83          	ld	s11,104(a1)

 460:	8082                	ret

0000000000000462 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 462:	1141                	addi	sp,sp,-16
 464:	e422                	sd	s0,8(sp)
 466:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 468:	87aa                	mv	a5,a0
 46a:	0585                	addi	a1,a1,1
 46c:	0785                	addi	a5,a5,1
 46e:	fff5c703          	lbu	a4,-1(a1)
 472:	fee78fa3          	sb	a4,-1(a5)
 476:	fb75                	bnez	a4,46a <strcpy+0x8>
    ;
  return os;
}
 478:	6422                	ld	s0,8(sp)
 47a:	0141                	addi	sp,sp,16
 47c:	8082                	ret

000000000000047e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 47e:	1141                	addi	sp,sp,-16
 480:	e422                	sd	s0,8(sp)
 482:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 484:	00054783          	lbu	a5,0(a0)
 488:	cb91                	beqz	a5,49c <strcmp+0x1e>
 48a:	0005c703          	lbu	a4,0(a1)
 48e:	00f71763          	bne	a4,a5,49c <strcmp+0x1e>
    p++, q++;
 492:	0505                	addi	a0,a0,1
 494:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 496:	00054783          	lbu	a5,0(a0)
 49a:	fbe5                	bnez	a5,48a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 49c:	0005c503          	lbu	a0,0(a1)
}
 4a0:	40a7853b          	subw	a0,a5,a0
 4a4:	6422                	ld	s0,8(sp)
 4a6:	0141                	addi	sp,sp,16
 4a8:	8082                	ret

00000000000004aa <strlen>:

uint
strlen(const char *s)
{
 4aa:	1141                	addi	sp,sp,-16
 4ac:	e422                	sd	s0,8(sp)
 4ae:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 4b0:	00054783          	lbu	a5,0(a0)
 4b4:	cf91                	beqz	a5,4d0 <strlen+0x26>
 4b6:	0505                	addi	a0,a0,1
 4b8:	87aa                	mv	a5,a0
 4ba:	4685                	li	a3,1
 4bc:	9e89                	subw	a3,a3,a0
 4be:	00f6853b          	addw	a0,a3,a5
 4c2:	0785                	addi	a5,a5,1
 4c4:	fff7c703          	lbu	a4,-1(a5)
 4c8:	fb7d                	bnez	a4,4be <strlen+0x14>
    ;
  return n;
}
 4ca:	6422                	ld	s0,8(sp)
 4cc:	0141                	addi	sp,sp,16
 4ce:	8082                	ret
  for(n = 0; s[n]; n++)
 4d0:	4501                	li	a0,0
 4d2:	bfe5                	j	4ca <strlen+0x20>

00000000000004d4 <memset>:

void*
memset(void *dst, int c, uint n)
{
 4d4:	1141                	addi	sp,sp,-16
 4d6:	e422                	sd	s0,8(sp)
 4d8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 4da:	ce09                	beqz	a2,4f4 <memset+0x20>
 4dc:	87aa                	mv	a5,a0
 4de:	fff6071b          	addiw	a4,a2,-1
 4e2:	1702                	slli	a4,a4,0x20
 4e4:	9301                	srli	a4,a4,0x20
 4e6:	0705                	addi	a4,a4,1
 4e8:	972a                	add	a4,a4,a0
    cdst[i] = c;
 4ea:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 4ee:	0785                	addi	a5,a5,1
 4f0:	fee79de3          	bne	a5,a4,4ea <memset+0x16>
  }
  return dst;
}
 4f4:	6422                	ld	s0,8(sp)
 4f6:	0141                	addi	sp,sp,16
 4f8:	8082                	ret

00000000000004fa <strchr>:

char*
strchr(const char *s, char c)
{
 4fa:	1141                	addi	sp,sp,-16
 4fc:	e422                	sd	s0,8(sp)
 4fe:	0800                	addi	s0,sp,16
  for(; *s; s++)
 500:	00054783          	lbu	a5,0(a0)
 504:	cb99                	beqz	a5,51a <strchr+0x20>
    if(*s == c)
 506:	00f58763          	beq	a1,a5,514 <strchr+0x1a>
  for(; *s; s++)
 50a:	0505                	addi	a0,a0,1
 50c:	00054783          	lbu	a5,0(a0)
 510:	fbfd                	bnez	a5,506 <strchr+0xc>
      return (char*)s;
  return 0;
 512:	4501                	li	a0,0
}
 514:	6422                	ld	s0,8(sp)
 516:	0141                	addi	sp,sp,16
 518:	8082                	ret
  return 0;
 51a:	4501                	li	a0,0
 51c:	bfe5                	j	514 <strchr+0x1a>

000000000000051e <gets>:

char*
gets(char *buf, int max)
{
 51e:	711d                	addi	sp,sp,-96
 520:	ec86                	sd	ra,88(sp)
 522:	e8a2                	sd	s0,80(sp)
 524:	e4a6                	sd	s1,72(sp)
 526:	e0ca                	sd	s2,64(sp)
 528:	fc4e                	sd	s3,56(sp)
 52a:	f852                	sd	s4,48(sp)
 52c:	f456                	sd	s5,40(sp)
 52e:	f05a                	sd	s6,32(sp)
 530:	ec5e                	sd	s7,24(sp)
 532:	1080                	addi	s0,sp,96
 534:	8baa                	mv	s7,a0
 536:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 538:	892a                	mv	s2,a0
 53a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 53c:	4aa9                	li	s5,10
 53e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 540:	89a6                	mv	s3,s1
 542:	2485                	addiw	s1,s1,1
 544:	0344d863          	bge	s1,s4,574 <gets+0x56>
    cc = read(0, &c, 1);
 548:	4605                	li	a2,1
 54a:	faf40593          	addi	a1,s0,-81
 54e:	4501                	li	a0,0
 550:	00000097          	auipc	ra,0x0
 554:	1a0080e7          	jalr	416(ra) # 6f0 <read>
    if(cc < 1)
 558:	00a05e63          	blez	a0,574 <gets+0x56>
    buf[i++] = c;
 55c:	faf44783          	lbu	a5,-81(s0)
 560:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 564:	01578763          	beq	a5,s5,572 <gets+0x54>
 568:	0905                	addi	s2,s2,1
 56a:	fd679be3          	bne	a5,s6,540 <gets+0x22>
  for(i=0; i+1 < max; ){
 56e:	89a6                	mv	s3,s1
 570:	a011                	j	574 <gets+0x56>
 572:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 574:	99de                	add	s3,s3,s7
 576:	00098023          	sb	zero,0(s3)
  return buf;
}
 57a:	855e                	mv	a0,s7
 57c:	60e6                	ld	ra,88(sp)
 57e:	6446                	ld	s0,80(sp)
 580:	64a6                	ld	s1,72(sp)
 582:	6906                	ld	s2,64(sp)
 584:	79e2                	ld	s3,56(sp)
 586:	7a42                	ld	s4,48(sp)
 588:	7aa2                	ld	s5,40(sp)
 58a:	7b02                	ld	s6,32(sp)
 58c:	6be2                	ld	s7,24(sp)
 58e:	6125                	addi	sp,sp,96
 590:	8082                	ret

0000000000000592 <stat>:

int
stat(const char *n, struct stat *st)
{
 592:	1101                	addi	sp,sp,-32
 594:	ec06                	sd	ra,24(sp)
 596:	e822                	sd	s0,16(sp)
 598:	e426                	sd	s1,8(sp)
 59a:	e04a                	sd	s2,0(sp)
 59c:	1000                	addi	s0,sp,32
 59e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 5a0:	4581                	li	a1,0
 5a2:	00000097          	auipc	ra,0x0
 5a6:	176080e7          	jalr	374(ra) # 718 <open>
  if(fd < 0)
 5aa:	02054563          	bltz	a0,5d4 <stat+0x42>
 5ae:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 5b0:	85ca                	mv	a1,s2
 5b2:	00000097          	auipc	ra,0x0
 5b6:	17e080e7          	jalr	382(ra) # 730 <fstat>
 5ba:	892a                	mv	s2,a0
  close(fd);
 5bc:	8526                	mv	a0,s1
 5be:	00000097          	auipc	ra,0x0
 5c2:	142080e7          	jalr	322(ra) # 700 <close>
  return r;
}
 5c6:	854a                	mv	a0,s2
 5c8:	60e2                	ld	ra,24(sp)
 5ca:	6442                	ld	s0,16(sp)
 5cc:	64a2                	ld	s1,8(sp)
 5ce:	6902                	ld	s2,0(sp)
 5d0:	6105                	addi	sp,sp,32
 5d2:	8082                	ret
    return -1;
 5d4:	597d                	li	s2,-1
 5d6:	bfc5                	j	5c6 <stat+0x34>

00000000000005d8 <atoi>:

int
atoi(const char *s)
{
 5d8:	1141                	addi	sp,sp,-16
 5da:	e422                	sd	s0,8(sp)
 5dc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 5de:	00054603          	lbu	a2,0(a0)
 5e2:	fd06079b          	addiw	a5,a2,-48
 5e6:	0ff7f793          	andi	a5,a5,255
 5ea:	4725                	li	a4,9
 5ec:	02f76963          	bltu	a4,a5,61e <atoi+0x46>
 5f0:	86aa                	mv	a3,a0
  n = 0;
 5f2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 5f4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 5f6:	0685                	addi	a3,a3,1
 5f8:	0025179b          	slliw	a5,a0,0x2
 5fc:	9fa9                	addw	a5,a5,a0
 5fe:	0017979b          	slliw	a5,a5,0x1
 602:	9fb1                	addw	a5,a5,a2
 604:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 608:	0006c603          	lbu	a2,0(a3)
 60c:	fd06071b          	addiw	a4,a2,-48
 610:	0ff77713          	andi	a4,a4,255
 614:	fee5f1e3          	bgeu	a1,a4,5f6 <atoi+0x1e>
  return n;
}
 618:	6422                	ld	s0,8(sp)
 61a:	0141                	addi	sp,sp,16
 61c:	8082                	ret
  n = 0;
 61e:	4501                	li	a0,0
 620:	bfe5                	j	618 <atoi+0x40>

0000000000000622 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 622:	1141                	addi	sp,sp,-16
 624:	e422                	sd	s0,8(sp)
 626:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 628:	02b57663          	bgeu	a0,a1,654 <memmove+0x32>
    while(n-- > 0)
 62c:	02c05163          	blez	a2,64e <memmove+0x2c>
 630:	fff6079b          	addiw	a5,a2,-1
 634:	1782                	slli	a5,a5,0x20
 636:	9381                	srli	a5,a5,0x20
 638:	0785                	addi	a5,a5,1
 63a:	97aa                	add	a5,a5,a0
  dst = vdst;
 63c:	872a                	mv	a4,a0
      *dst++ = *src++;
 63e:	0585                	addi	a1,a1,1
 640:	0705                	addi	a4,a4,1
 642:	fff5c683          	lbu	a3,-1(a1)
 646:	fed70fa3          	sb	a3,-1(a4) # 1fff <__global_pointer$+0xaee>
    while(n-- > 0)
 64a:	fee79ae3          	bne	a5,a4,63e <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 64e:	6422                	ld	s0,8(sp)
 650:	0141                	addi	sp,sp,16
 652:	8082                	ret
    dst += n;
 654:	00c50733          	add	a4,a0,a2
    src += n;
 658:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 65a:	fec05ae3          	blez	a2,64e <memmove+0x2c>
 65e:	fff6079b          	addiw	a5,a2,-1
 662:	1782                	slli	a5,a5,0x20
 664:	9381                	srli	a5,a5,0x20
 666:	fff7c793          	not	a5,a5
 66a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 66c:	15fd                	addi	a1,a1,-1
 66e:	177d                	addi	a4,a4,-1
 670:	0005c683          	lbu	a3,0(a1)
 674:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 678:	fee79ae3          	bne	a5,a4,66c <memmove+0x4a>
 67c:	bfc9                	j	64e <memmove+0x2c>

000000000000067e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 67e:	1141                	addi	sp,sp,-16
 680:	e422                	sd	s0,8(sp)
 682:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 684:	ca05                	beqz	a2,6b4 <memcmp+0x36>
 686:	fff6069b          	addiw	a3,a2,-1
 68a:	1682                	slli	a3,a3,0x20
 68c:	9281                	srli	a3,a3,0x20
 68e:	0685                	addi	a3,a3,1
 690:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 692:	00054783          	lbu	a5,0(a0)
 696:	0005c703          	lbu	a4,0(a1)
 69a:	00e79863          	bne	a5,a4,6aa <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 69e:	0505                	addi	a0,a0,1
    p2++;
 6a0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 6a2:	fed518e3          	bne	a0,a3,692 <memcmp+0x14>
  }
  return 0;
 6a6:	4501                	li	a0,0
 6a8:	a019                	j	6ae <memcmp+0x30>
      return *p1 - *p2;
 6aa:	40e7853b          	subw	a0,a5,a4
}
 6ae:	6422                	ld	s0,8(sp)
 6b0:	0141                	addi	sp,sp,16
 6b2:	8082                	ret
  return 0;
 6b4:	4501                	li	a0,0
 6b6:	bfe5                	j	6ae <memcmp+0x30>

00000000000006b8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 6b8:	1141                	addi	sp,sp,-16
 6ba:	e406                	sd	ra,8(sp)
 6bc:	e022                	sd	s0,0(sp)
 6be:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 6c0:	00000097          	auipc	ra,0x0
 6c4:	f62080e7          	jalr	-158(ra) # 622 <memmove>
}
 6c8:	60a2                	ld	ra,8(sp)
 6ca:	6402                	ld	s0,0(sp)
 6cc:	0141                	addi	sp,sp,16
 6ce:	8082                	ret

00000000000006d0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 6d0:	4885                	li	a7,1
 ecall
 6d2:	00000073          	ecall
 ret
 6d6:	8082                	ret

00000000000006d8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 6d8:	4889                	li	a7,2
 ecall
 6da:	00000073          	ecall
 ret
 6de:	8082                	ret

00000000000006e0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 6e0:	488d                	li	a7,3
 ecall
 6e2:	00000073          	ecall
 ret
 6e6:	8082                	ret

00000000000006e8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 6e8:	4891                	li	a7,4
 ecall
 6ea:	00000073          	ecall
 ret
 6ee:	8082                	ret

00000000000006f0 <read>:
.global read
read:
 li a7, SYS_read
 6f0:	4895                	li	a7,5
 ecall
 6f2:	00000073          	ecall
 ret
 6f6:	8082                	ret

00000000000006f8 <write>:
.global write
write:
 li a7, SYS_write
 6f8:	48c1                	li	a7,16
 ecall
 6fa:	00000073          	ecall
 ret
 6fe:	8082                	ret

0000000000000700 <close>:
.global close
close:
 li a7, SYS_close
 700:	48d5                	li	a7,21
 ecall
 702:	00000073          	ecall
 ret
 706:	8082                	ret

0000000000000708 <kill>:
.global kill
kill:
 li a7, SYS_kill
 708:	4899                	li	a7,6
 ecall
 70a:	00000073          	ecall
 ret
 70e:	8082                	ret

0000000000000710 <exec>:
.global exec
exec:
 li a7, SYS_exec
 710:	489d                	li	a7,7
 ecall
 712:	00000073          	ecall
 ret
 716:	8082                	ret

0000000000000718 <open>:
.global open
open:
 li a7, SYS_open
 718:	48bd                	li	a7,15
 ecall
 71a:	00000073          	ecall
 ret
 71e:	8082                	ret

0000000000000720 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 720:	48c5                	li	a7,17
 ecall
 722:	00000073          	ecall
 ret
 726:	8082                	ret

0000000000000728 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 728:	48c9                	li	a7,18
 ecall
 72a:	00000073          	ecall
 ret
 72e:	8082                	ret

0000000000000730 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 730:	48a1                	li	a7,8
 ecall
 732:	00000073          	ecall
 ret
 736:	8082                	ret

0000000000000738 <link>:
.global link
link:
 li a7, SYS_link
 738:	48cd                	li	a7,19
 ecall
 73a:	00000073          	ecall
 ret
 73e:	8082                	ret

0000000000000740 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 740:	48d1                	li	a7,20
 ecall
 742:	00000073          	ecall
 ret
 746:	8082                	ret

0000000000000748 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 748:	48a5                	li	a7,9
 ecall
 74a:	00000073          	ecall
 ret
 74e:	8082                	ret

0000000000000750 <dup>:
.global dup
dup:
 li a7, SYS_dup
 750:	48a9                	li	a7,10
 ecall
 752:	00000073          	ecall
 ret
 756:	8082                	ret

0000000000000758 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 758:	48ad                	li	a7,11
 ecall
 75a:	00000073          	ecall
 ret
 75e:	8082                	ret

0000000000000760 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 760:	48b1                	li	a7,12
 ecall
 762:	00000073          	ecall
 ret
 766:	8082                	ret

0000000000000768 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 768:	48b5                	li	a7,13
 ecall
 76a:	00000073          	ecall
 ret
 76e:	8082                	ret

0000000000000770 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 770:	48b9                	li	a7,14
 ecall
 772:	00000073          	ecall
 ret
 776:	8082                	ret

0000000000000778 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 778:	1101                	addi	sp,sp,-32
 77a:	ec06                	sd	ra,24(sp)
 77c:	e822                	sd	s0,16(sp)
 77e:	1000                	addi	s0,sp,32
 780:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 784:	4605                	li	a2,1
 786:	fef40593          	addi	a1,s0,-17
 78a:	00000097          	auipc	ra,0x0
 78e:	f6e080e7          	jalr	-146(ra) # 6f8 <write>
}
 792:	60e2                	ld	ra,24(sp)
 794:	6442                	ld	s0,16(sp)
 796:	6105                	addi	sp,sp,32
 798:	8082                	ret

000000000000079a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 79a:	7139                	addi	sp,sp,-64
 79c:	fc06                	sd	ra,56(sp)
 79e:	f822                	sd	s0,48(sp)
 7a0:	f426                	sd	s1,40(sp)
 7a2:	f04a                	sd	s2,32(sp)
 7a4:	ec4e                	sd	s3,24(sp)
 7a6:	0080                	addi	s0,sp,64
 7a8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 7aa:	c299                	beqz	a3,7b0 <printint+0x16>
 7ac:	0805c863          	bltz	a1,83c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 7b0:	2581                	sext.w	a1,a1
  neg = 0;
 7b2:	4881                	li	a7,0
 7b4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 7b8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 7ba:	2601                	sext.w	a2,a2
 7bc:	00000517          	auipc	a0,0x0
 7c0:	54450513          	addi	a0,a0,1348 # d00 <digits>
 7c4:	883a                	mv	a6,a4
 7c6:	2705                	addiw	a4,a4,1
 7c8:	02c5f7bb          	remuw	a5,a1,a2
 7cc:	1782                	slli	a5,a5,0x20
 7ce:	9381                	srli	a5,a5,0x20
 7d0:	97aa                	add	a5,a5,a0
 7d2:	0007c783          	lbu	a5,0(a5)
 7d6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 7da:	0005879b          	sext.w	a5,a1
 7de:	02c5d5bb          	divuw	a1,a1,a2
 7e2:	0685                	addi	a3,a3,1
 7e4:	fec7f0e3          	bgeu	a5,a2,7c4 <printint+0x2a>
  if(neg)
 7e8:	00088b63          	beqz	a7,7fe <printint+0x64>
    buf[i++] = '-';
 7ec:	fd040793          	addi	a5,s0,-48
 7f0:	973e                	add	a4,a4,a5
 7f2:	02d00793          	li	a5,45
 7f6:	fef70823          	sb	a5,-16(a4)
 7fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 7fe:	02e05863          	blez	a4,82e <printint+0x94>
 802:	fc040793          	addi	a5,s0,-64
 806:	00e78933          	add	s2,a5,a4
 80a:	fff78993          	addi	s3,a5,-1
 80e:	99ba                	add	s3,s3,a4
 810:	377d                	addiw	a4,a4,-1
 812:	1702                	slli	a4,a4,0x20
 814:	9301                	srli	a4,a4,0x20
 816:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 81a:	fff94583          	lbu	a1,-1(s2)
 81e:	8526                	mv	a0,s1
 820:	00000097          	auipc	ra,0x0
 824:	f58080e7          	jalr	-168(ra) # 778 <putc>
  while(--i >= 0)
 828:	197d                	addi	s2,s2,-1
 82a:	ff3918e3          	bne	s2,s3,81a <printint+0x80>
}
 82e:	70e2                	ld	ra,56(sp)
 830:	7442                	ld	s0,48(sp)
 832:	74a2                	ld	s1,40(sp)
 834:	7902                	ld	s2,32(sp)
 836:	69e2                	ld	s3,24(sp)
 838:	6121                	addi	sp,sp,64
 83a:	8082                	ret
    x = -xx;
 83c:	40b005bb          	negw	a1,a1
    neg = 1;
 840:	4885                	li	a7,1
    x = -xx;
 842:	bf8d                	j	7b4 <printint+0x1a>

0000000000000844 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 844:	7119                	addi	sp,sp,-128
 846:	fc86                	sd	ra,120(sp)
 848:	f8a2                	sd	s0,112(sp)
 84a:	f4a6                	sd	s1,104(sp)
 84c:	f0ca                	sd	s2,96(sp)
 84e:	ecce                	sd	s3,88(sp)
 850:	e8d2                	sd	s4,80(sp)
 852:	e4d6                	sd	s5,72(sp)
 854:	e0da                	sd	s6,64(sp)
 856:	fc5e                	sd	s7,56(sp)
 858:	f862                	sd	s8,48(sp)
 85a:	f466                	sd	s9,40(sp)
 85c:	f06a                	sd	s10,32(sp)
 85e:	ec6e                	sd	s11,24(sp)
 860:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 862:	0005c903          	lbu	s2,0(a1)
 866:	18090f63          	beqz	s2,a04 <vprintf+0x1c0>
 86a:	8aaa                	mv	s5,a0
 86c:	8b32                	mv	s6,a2
 86e:	00158493          	addi	s1,a1,1
  state = 0;
 872:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 874:	02500a13          	li	s4,37
      if(c == 'd'){
 878:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 87c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 880:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 884:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 888:	00000b97          	auipc	s7,0x0
 88c:	478b8b93          	addi	s7,s7,1144 # d00 <digits>
 890:	a839                	j	8ae <vprintf+0x6a>
        putc(fd, c);
 892:	85ca                	mv	a1,s2
 894:	8556                	mv	a0,s5
 896:	00000097          	auipc	ra,0x0
 89a:	ee2080e7          	jalr	-286(ra) # 778 <putc>
 89e:	a019                	j	8a4 <vprintf+0x60>
    } else if(state == '%'){
 8a0:	01498f63          	beq	s3,s4,8be <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 8a4:	0485                	addi	s1,s1,1
 8a6:	fff4c903          	lbu	s2,-1(s1)
 8aa:	14090d63          	beqz	s2,a04 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 8ae:	0009079b          	sext.w	a5,s2
    if(state == 0){
 8b2:	fe0997e3          	bnez	s3,8a0 <vprintf+0x5c>
      if(c == '%'){
 8b6:	fd479ee3          	bne	a5,s4,892 <vprintf+0x4e>
        state = '%';
 8ba:	89be                	mv	s3,a5
 8bc:	b7e5                	j	8a4 <vprintf+0x60>
      if(c == 'd'){
 8be:	05878063          	beq	a5,s8,8fe <vprintf+0xba>
      } else if(c == 'l') {
 8c2:	05978c63          	beq	a5,s9,91a <vprintf+0xd6>
      } else if(c == 'x') {
 8c6:	07a78863          	beq	a5,s10,936 <vprintf+0xf2>
      } else if(c == 'p') {
 8ca:	09b78463          	beq	a5,s11,952 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 8ce:	07300713          	li	a4,115
 8d2:	0ce78663          	beq	a5,a4,99e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 8d6:	06300713          	li	a4,99
 8da:	0ee78e63          	beq	a5,a4,9d6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 8de:	11478863          	beq	a5,s4,9ee <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 8e2:	85d2                	mv	a1,s4
 8e4:	8556                	mv	a0,s5
 8e6:	00000097          	auipc	ra,0x0
 8ea:	e92080e7          	jalr	-366(ra) # 778 <putc>
        putc(fd, c);
 8ee:	85ca                	mv	a1,s2
 8f0:	8556                	mv	a0,s5
 8f2:	00000097          	auipc	ra,0x0
 8f6:	e86080e7          	jalr	-378(ra) # 778 <putc>
      }
      state = 0;
 8fa:	4981                	li	s3,0
 8fc:	b765                	j	8a4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 8fe:	008b0913          	addi	s2,s6,8
 902:	4685                	li	a3,1
 904:	4629                	li	a2,10
 906:	000b2583          	lw	a1,0(s6)
 90a:	8556                	mv	a0,s5
 90c:	00000097          	auipc	ra,0x0
 910:	e8e080e7          	jalr	-370(ra) # 79a <printint>
 914:	8b4a                	mv	s6,s2
      state = 0;
 916:	4981                	li	s3,0
 918:	b771                	j	8a4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 91a:	008b0913          	addi	s2,s6,8
 91e:	4681                	li	a3,0
 920:	4629                	li	a2,10
 922:	000b2583          	lw	a1,0(s6)
 926:	8556                	mv	a0,s5
 928:	00000097          	auipc	ra,0x0
 92c:	e72080e7          	jalr	-398(ra) # 79a <printint>
 930:	8b4a                	mv	s6,s2
      state = 0;
 932:	4981                	li	s3,0
 934:	bf85                	j	8a4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 936:	008b0913          	addi	s2,s6,8
 93a:	4681                	li	a3,0
 93c:	4641                	li	a2,16
 93e:	000b2583          	lw	a1,0(s6)
 942:	8556                	mv	a0,s5
 944:	00000097          	auipc	ra,0x0
 948:	e56080e7          	jalr	-426(ra) # 79a <printint>
 94c:	8b4a                	mv	s6,s2
      state = 0;
 94e:	4981                	li	s3,0
 950:	bf91                	j	8a4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 952:	008b0793          	addi	a5,s6,8
 956:	f8f43423          	sd	a5,-120(s0)
 95a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 95e:	03000593          	li	a1,48
 962:	8556                	mv	a0,s5
 964:	00000097          	auipc	ra,0x0
 968:	e14080e7          	jalr	-492(ra) # 778 <putc>
  putc(fd, 'x');
 96c:	85ea                	mv	a1,s10
 96e:	8556                	mv	a0,s5
 970:	00000097          	auipc	ra,0x0
 974:	e08080e7          	jalr	-504(ra) # 778 <putc>
 978:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 97a:	03c9d793          	srli	a5,s3,0x3c
 97e:	97de                	add	a5,a5,s7
 980:	0007c583          	lbu	a1,0(a5)
 984:	8556                	mv	a0,s5
 986:	00000097          	auipc	ra,0x0
 98a:	df2080e7          	jalr	-526(ra) # 778 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 98e:	0992                	slli	s3,s3,0x4
 990:	397d                	addiw	s2,s2,-1
 992:	fe0914e3          	bnez	s2,97a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 996:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 99a:	4981                	li	s3,0
 99c:	b721                	j	8a4 <vprintf+0x60>
        s = va_arg(ap, char*);
 99e:	008b0993          	addi	s3,s6,8
 9a2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 9a6:	02090163          	beqz	s2,9c8 <vprintf+0x184>
        while(*s != 0){
 9aa:	00094583          	lbu	a1,0(s2)
 9ae:	c9a1                	beqz	a1,9fe <vprintf+0x1ba>
          putc(fd, *s);
 9b0:	8556                	mv	a0,s5
 9b2:	00000097          	auipc	ra,0x0
 9b6:	dc6080e7          	jalr	-570(ra) # 778 <putc>
          s++;
 9ba:	0905                	addi	s2,s2,1
        while(*s != 0){
 9bc:	00094583          	lbu	a1,0(s2)
 9c0:	f9e5                	bnez	a1,9b0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 9c2:	8b4e                	mv	s6,s3
      state = 0;
 9c4:	4981                	li	s3,0
 9c6:	bdf9                	j	8a4 <vprintf+0x60>
          s = "(null)";
 9c8:	00000917          	auipc	s2,0x0
 9cc:	33090913          	addi	s2,s2,816 # cf8 <malloc+0x1ea>
        while(*s != 0){
 9d0:	02800593          	li	a1,40
 9d4:	bff1                	j	9b0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 9d6:	008b0913          	addi	s2,s6,8
 9da:	000b4583          	lbu	a1,0(s6)
 9de:	8556                	mv	a0,s5
 9e0:	00000097          	auipc	ra,0x0
 9e4:	d98080e7          	jalr	-616(ra) # 778 <putc>
 9e8:	8b4a                	mv	s6,s2
      state = 0;
 9ea:	4981                	li	s3,0
 9ec:	bd65                	j	8a4 <vprintf+0x60>
        putc(fd, c);
 9ee:	85d2                	mv	a1,s4
 9f0:	8556                	mv	a0,s5
 9f2:	00000097          	auipc	ra,0x0
 9f6:	d86080e7          	jalr	-634(ra) # 778 <putc>
      state = 0;
 9fa:	4981                	li	s3,0
 9fc:	b565                	j	8a4 <vprintf+0x60>
        s = va_arg(ap, char*);
 9fe:	8b4e                	mv	s6,s3
      state = 0;
 a00:	4981                	li	s3,0
 a02:	b54d                	j	8a4 <vprintf+0x60>
    }
  }
}
 a04:	70e6                	ld	ra,120(sp)
 a06:	7446                	ld	s0,112(sp)
 a08:	74a6                	ld	s1,104(sp)
 a0a:	7906                	ld	s2,96(sp)
 a0c:	69e6                	ld	s3,88(sp)
 a0e:	6a46                	ld	s4,80(sp)
 a10:	6aa6                	ld	s5,72(sp)
 a12:	6b06                	ld	s6,64(sp)
 a14:	7be2                	ld	s7,56(sp)
 a16:	7c42                	ld	s8,48(sp)
 a18:	7ca2                	ld	s9,40(sp)
 a1a:	7d02                	ld	s10,32(sp)
 a1c:	6de2                	ld	s11,24(sp)
 a1e:	6109                	addi	sp,sp,128
 a20:	8082                	ret

0000000000000a22 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a22:	715d                	addi	sp,sp,-80
 a24:	ec06                	sd	ra,24(sp)
 a26:	e822                	sd	s0,16(sp)
 a28:	1000                	addi	s0,sp,32
 a2a:	e010                	sd	a2,0(s0)
 a2c:	e414                	sd	a3,8(s0)
 a2e:	e818                	sd	a4,16(s0)
 a30:	ec1c                	sd	a5,24(s0)
 a32:	03043023          	sd	a6,32(s0)
 a36:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a3a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a3e:	8622                	mv	a2,s0
 a40:	00000097          	auipc	ra,0x0
 a44:	e04080e7          	jalr	-508(ra) # 844 <vprintf>
}
 a48:	60e2                	ld	ra,24(sp)
 a4a:	6442                	ld	s0,16(sp)
 a4c:	6161                	addi	sp,sp,80
 a4e:	8082                	ret

0000000000000a50 <printf>:

void
printf(const char *fmt, ...)
{
 a50:	711d                	addi	sp,sp,-96
 a52:	ec06                	sd	ra,24(sp)
 a54:	e822                	sd	s0,16(sp)
 a56:	1000                	addi	s0,sp,32
 a58:	e40c                	sd	a1,8(s0)
 a5a:	e810                	sd	a2,16(s0)
 a5c:	ec14                	sd	a3,24(s0)
 a5e:	f018                	sd	a4,32(s0)
 a60:	f41c                	sd	a5,40(s0)
 a62:	03043823          	sd	a6,48(s0)
 a66:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 a6a:	00840613          	addi	a2,s0,8
 a6e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 a72:	85aa                	mv	a1,a0
 a74:	4505                	li	a0,1
 a76:	00000097          	auipc	ra,0x0
 a7a:	dce080e7          	jalr	-562(ra) # 844 <vprintf>
}
 a7e:	60e2                	ld	ra,24(sp)
 a80:	6442                	ld	s0,16(sp)
 a82:	6125                	addi	sp,sp,96
 a84:	8082                	ret

0000000000000a86 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a86:	1141                	addi	sp,sp,-16
 a88:	e422                	sd	s0,8(sp)
 a8a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a8c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a90:	00000797          	auipc	a5,0x0
 a94:	2a87b783          	ld	a5,680(a5) # d38 <freep>
 a98:	a805                	j	ac8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 a9a:	4618                	lw	a4,8(a2)
 a9c:	9db9                	addw	a1,a1,a4
 a9e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 aa2:	6398                	ld	a4,0(a5)
 aa4:	6318                	ld	a4,0(a4)
 aa6:	fee53823          	sd	a4,-16(a0)
 aaa:	a091                	j	aee <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 aac:	ff852703          	lw	a4,-8(a0)
 ab0:	9e39                	addw	a2,a2,a4
 ab2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 ab4:	ff053703          	ld	a4,-16(a0)
 ab8:	e398                	sd	a4,0(a5)
 aba:	a099                	j	b00 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 abc:	6398                	ld	a4,0(a5)
 abe:	00e7e463          	bltu	a5,a4,ac6 <free+0x40>
 ac2:	00e6ea63          	bltu	a3,a4,ad6 <free+0x50>
{
 ac6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ac8:	fed7fae3          	bgeu	a5,a3,abc <free+0x36>
 acc:	6398                	ld	a4,0(a5)
 ace:	00e6e463          	bltu	a3,a4,ad6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 ad2:	fee7eae3          	bltu	a5,a4,ac6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 ad6:	ff852583          	lw	a1,-8(a0)
 ada:	6390                	ld	a2,0(a5)
 adc:	02059713          	slli	a4,a1,0x20
 ae0:	9301                	srli	a4,a4,0x20
 ae2:	0712                	slli	a4,a4,0x4
 ae4:	9736                	add	a4,a4,a3
 ae6:	fae60ae3          	beq	a2,a4,a9a <free+0x14>
    bp->s.ptr = p->s.ptr;
 aea:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 aee:	4790                	lw	a2,8(a5)
 af0:	02061713          	slli	a4,a2,0x20
 af4:	9301                	srli	a4,a4,0x20
 af6:	0712                	slli	a4,a4,0x4
 af8:	973e                	add	a4,a4,a5
 afa:	fae689e3          	beq	a3,a4,aac <free+0x26>
  } else
    p->s.ptr = bp;
 afe:	e394                	sd	a3,0(a5)
  freep = p;
 b00:	00000717          	auipc	a4,0x0
 b04:	22f73c23          	sd	a5,568(a4) # d38 <freep>
}
 b08:	6422                	ld	s0,8(sp)
 b0a:	0141                	addi	sp,sp,16
 b0c:	8082                	ret

0000000000000b0e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 b0e:	7139                	addi	sp,sp,-64
 b10:	fc06                	sd	ra,56(sp)
 b12:	f822                	sd	s0,48(sp)
 b14:	f426                	sd	s1,40(sp)
 b16:	f04a                	sd	s2,32(sp)
 b18:	ec4e                	sd	s3,24(sp)
 b1a:	e852                	sd	s4,16(sp)
 b1c:	e456                	sd	s5,8(sp)
 b1e:	e05a                	sd	s6,0(sp)
 b20:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b22:	02051493          	slli	s1,a0,0x20
 b26:	9081                	srli	s1,s1,0x20
 b28:	04bd                	addi	s1,s1,15
 b2a:	8091                	srli	s1,s1,0x4
 b2c:	0014899b          	addiw	s3,s1,1
 b30:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 b32:	00000517          	auipc	a0,0x0
 b36:	20653503          	ld	a0,518(a0) # d38 <freep>
 b3a:	c515                	beqz	a0,b66 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b3c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b3e:	4798                	lw	a4,8(a5)
 b40:	02977f63          	bgeu	a4,s1,b7e <malloc+0x70>
 b44:	8a4e                	mv	s4,s3
 b46:	0009871b          	sext.w	a4,s3
 b4a:	6685                	lui	a3,0x1
 b4c:	00d77363          	bgeu	a4,a3,b52 <malloc+0x44>
 b50:	6a05                	lui	s4,0x1
 b52:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 b56:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 b5a:	00000917          	auipc	s2,0x0
 b5e:	1de90913          	addi	s2,s2,478 # d38 <freep>
  if(p == (char*)-1)
 b62:	5afd                	li	s5,-1
 b64:	a88d                	j	bd6 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 b66:	00008797          	auipc	a5,0x8
 b6a:	3ba78793          	addi	a5,a5,954 # 8f20 <base>
 b6e:	00000717          	auipc	a4,0x0
 b72:	1cf73523          	sd	a5,458(a4) # d38 <freep>
 b76:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 b78:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 b7c:	b7e1                	j	b44 <malloc+0x36>
      if(p->s.size == nunits)
 b7e:	02e48b63          	beq	s1,a4,bb4 <malloc+0xa6>
        p->s.size -= nunits;
 b82:	4137073b          	subw	a4,a4,s3
 b86:	c798                	sw	a4,8(a5)
        p += p->s.size;
 b88:	1702                	slli	a4,a4,0x20
 b8a:	9301                	srli	a4,a4,0x20
 b8c:	0712                	slli	a4,a4,0x4
 b8e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 b90:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 b94:	00000717          	auipc	a4,0x0
 b98:	1aa73223          	sd	a0,420(a4) # d38 <freep>
      return (void*)(p + 1);
 b9c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 ba0:	70e2                	ld	ra,56(sp)
 ba2:	7442                	ld	s0,48(sp)
 ba4:	74a2                	ld	s1,40(sp)
 ba6:	7902                	ld	s2,32(sp)
 ba8:	69e2                	ld	s3,24(sp)
 baa:	6a42                	ld	s4,16(sp)
 bac:	6aa2                	ld	s5,8(sp)
 bae:	6b02                	ld	s6,0(sp)
 bb0:	6121                	addi	sp,sp,64
 bb2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 bb4:	6398                	ld	a4,0(a5)
 bb6:	e118                	sd	a4,0(a0)
 bb8:	bff1                	j	b94 <malloc+0x86>
  hp->s.size = nu;
 bba:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 bbe:	0541                	addi	a0,a0,16
 bc0:	00000097          	auipc	ra,0x0
 bc4:	ec6080e7          	jalr	-314(ra) # a86 <free>
  return freep;
 bc8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 bcc:	d971                	beqz	a0,ba0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 bce:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bd0:	4798                	lw	a4,8(a5)
 bd2:	fa9776e3          	bgeu	a4,s1,b7e <malloc+0x70>
    if(p == freep)
 bd6:	00093703          	ld	a4,0(s2)
 bda:	853e                	mv	a0,a5
 bdc:	fef719e3          	bne	a4,a5,bce <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 be0:	8552                	mv	a0,s4
 be2:	00000097          	auipc	ra,0x0
 be6:	b7e080e7          	jalr	-1154(ra) # 760 <sbrk>
  if(p == (char*)-1)
 bea:	fd5518e3          	bne	a0,s5,bba <malloc+0xac>
        return 0;
 bee:	4501                	li	a0,0
 bf0:	bf45                	j	ba0 <malloc+0x92>
