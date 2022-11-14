
vmm/guest/obj/user/vmm:     file format elf64-x86-64


Disassembly of section .text:

0000000000800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	movabs $USTACKTOP, %rax
  800020:	48 b8 00 e0 7f ef 00 	movabs $0xef7fe000,%rax
  800027:	00 00 00 
	cmpq %rax,%rsp
  80002a:	48 39 c4             	cmp    %rax,%rsp
	jne args_exist
  80002d:	75 04                	jne    800033 <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushq $0
  80002f:	6a 00                	pushq  $0x0
	pushq $0
  800031:	6a 00                	pushq  $0x0

0000000000800033 <args_exist>:

args_exist:
	movq 8(%rsp), %rsi
  800033:	48 8b 74 24 08       	mov    0x8(%rsp),%rsi
	movq (%rsp), %rdi
  800038:	48 8b 3c 24          	mov    (%rsp),%rdi
	call libmain
  80003c:	e8 bd 05 00 00       	callq  8005fe <libmain>
1:	jmp 1b
  800041:	eb fe                	jmp    800041 <args_exist+0xe>

0000000000800043 <map_in_guest>:
// Return 0 on success, <0 on failure.
//
// Hint: Call sys_ept_map() for mapping page. 
static int
map_in_guest( envid_t guest, uintptr_t gpa, size_t memsz, 
	      int fd, size_t filesz, off_t fileoffset ) {
  800043:	55                   	push   %rbp
  800044:	48 89 e5             	mov    %rsp,%rbp
  800047:	48 83 ec 50          	sub    $0x50,%rsp
  80004b:	89 7d dc             	mov    %edi,-0x24(%rbp)
  80004e:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  800052:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  800056:	89 4d d8             	mov    %ecx,-0x28(%rbp)
  800059:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  80005d:	44 89 4d bc          	mov    %r9d,-0x44(%rbp)
	int i, ret;

	i = PGOFF(gpa);
  800061:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800065:	25 ff 0f 00 00       	and    $0xfff,%eax
  80006a:	89 45 fc             	mov    %eax,-0x4(%rbp)
	// if the provided guest physical address is not page-aligned, 
	// adjust our values so we are working with a page-aligned address
	if (i) {
  80006d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800071:	74 21                	je     800094 <map_in_guest+0x51>
		gpa -= i;
  800073:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800076:	48 98                	cltq   
  800078:	48 29 45 d0          	sub    %rax,-0x30(%rbp)
		memsz += i;
  80007c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80007f:	48 98                	cltq   
  800081:	48 01 45 c8          	add    %rax,-0x38(%rbp)
		filesz += i;
  800085:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800088:	48 98                	cltq   
  80008a:	48 01 45 c0          	add    %rax,-0x40(%rbp)
		fileoffset -= i;
  80008e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800091:	29 45 bc             	sub    %eax,-0x44(%rbp)
	}

	// walk through the provided region page by page and copy in the file contents
	// the the physical memory region of the guest
	for (i = 0; i < memsz; i += PGSIZE) {
  800094:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80009b:	e9 61 01 00 00       	jmpq   800201 <map_in_guest+0x1be>
		// allocate a temporary page
		ret = sys_page_alloc(0, UTEMP, PTE_P | PTE_U | PTE_W);
  8000a0:	ba 07 00 00 00       	mov    $0x7,%edx
  8000a5:	be 00 00 40 00       	mov    $0x400000,%esi
  8000aa:	bf 00 00 00 00       	mov    $0x0,%edi
  8000af:	48 b8 ad 1c 80 00 00 	movabs $0x801cad,%rax
  8000b6:	00 00 00 
  8000b9:	ff d0                	callq  *%rax
  8000bb:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  8000be:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8000c2:	79 1e                	jns    8000e2 <map_in_guest+0x9f>
			sys_page_unmap(0, UTEMP);
  8000c4:	be 00 00 40 00       	mov    $0x400000,%esi
  8000c9:	bf 00 00 00 00       	mov    $0x0,%edi
  8000ce:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  8000d5:	00 00 00 
  8000d8:	ff d0                	callq  *%rax
			return ret;
  8000da:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8000dd:	e9 33 01 00 00       	jmpq   800215 <map_in_guest+0x1d2>
		}
		// seek to the location to write the file contents at
		ret = seek(fd, fileoffset + i);
  8000e2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8000e5:	8b 55 bc             	mov    -0x44(%rbp),%edx
  8000e8:	01 c2                	add    %eax,%edx
  8000ea:	8b 45 d8             	mov    -0x28(%rbp),%eax
  8000ed:	89 d6                	mov    %edx,%esi
  8000ef:	89 c7                	mov    %eax,%edi
  8000f1:	48 b8 c3 27 80 00 00 	movabs $0x8027c3,%rax
  8000f8:	00 00 00 
  8000fb:	ff d0                	callq  *%rax
  8000fd:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  800100:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800104:	79 1e                	jns    800124 <map_in_guest+0xe1>
			sys_page_unmap(0, UTEMP);
  800106:	be 00 00 40 00       	mov    $0x400000,%esi
  80010b:	bf 00 00 00 00       	mov    $0x0,%edi
  800110:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  800117:	00 00 00 
  80011a:	ff d0                	callq  *%rax
			return ret;
  80011c:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80011f:	e9 f1 00 00 00       	jmpq   800215 <map_in_guest+0x1d2>
		}
		// read file contents into the mapped page
		ret = readn(fd, UTEMP, MIN(PGSIZE, filesz-i));
  800124:	c7 45 f4 00 10 00 00 	movl   $0x1000,-0xc(%rbp)
  80012b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80012e:	48 98                	cltq   
  800130:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800134:	48 29 c2             	sub    %rax,%rdx
  800137:	48 89 d0             	mov    %rdx,%rax
  80013a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80013e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  800141:	48 63 d0             	movslq %eax,%rdx
  800144:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800148:	48 39 c2             	cmp    %rax,%rdx
  80014b:	48 0f 47 d0          	cmova  %rax,%rdx
  80014f:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800152:	be 00 00 40 00       	mov    $0x400000,%esi
  800157:	89 c7                	mov    %eax,%edi
  800159:	48 b8 7a 26 80 00 00 	movabs $0x80267a,%rax
  800160:	00 00 00 
  800163:	ff d0                	callq  *%rax
  800165:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  800168:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  80016c:	79 1e                	jns    80018c <map_in_guest+0x149>
			sys_page_unmap(0, UTEMP);
  80016e:	be 00 00 40 00       	mov    $0x400000,%esi
  800173:	bf 00 00 00 00       	mov    $0x0,%edi
  800178:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  80017f:	00 00 00 
  800182:	ff d0                	callq  *%rax
			return ret;
  800184:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800187:	e9 89 00 00 00       	jmpq   800215 <map_in_guest+0x1d2>
		}
		// map the page in the EPT
		ret = sys_ept_map(0, UTEMP, guest, (void*) (gpa + i), __EPTE_FULL);
  80018c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80018f:	48 63 d0             	movslq %eax,%rdx
  800192:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800196:	48 01 d0             	add    %rdx,%rax
  800199:	48 89 c2             	mov    %rax,%rdx
  80019c:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80019f:	41 b8 07 00 00 00    	mov    $0x7,%r8d
  8001a5:	48 89 d1             	mov    %rdx,%rcx
  8001a8:	89 c2                	mov    %eax,%edx
  8001aa:	be 00 00 40 00       	mov    $0x400000,%esi
  8001af:	bf 00 00 00 00       	mov    $0x0,%edi
  8001b4:	48 b8 e8 1f 80 00 00 	movabs $0x801fe8,%rax
  8001bb:	00 00 00 
  8001be:	ff d0                	callq  *%rax
  8001c0:	89 45 f8             	mov    %eax,-0x8(%rbp)
		if (ret < 0) {
  8001c3:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8001c7:	79 1b                	jns    8001e4 <map_in_guest+0x1a1>
			sys_page_unmap(0, UTEMP);
  8001c9:	be 00 00 40 00       	mov    $0x400000,%esi
  8001ce:	bf 00 00 00 00       	mov    $0x0,%edi
  8001d3:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  8001da:	00 00 00 
  8001dd:	ff d0                	callq  *%rax
			return ret;
  8001df:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8001e2:	eb 31                	jmp    800215 <map_in_guest+0x1d2>
		}
		sys_page_unmap(0, UTEMP);
  8001e4:	be 00 00 40 00       	mov    $0x400000,%esi
  8001e9:	bf 00 00 00 00       	mov    $0x0,%edi
  8001ee:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  8001f5:	00 00 00 
  8001f8:	ff d0                	callq  *%rax
		fileoffset -= i;
	}

	// walk through the provided region page by page and copy in the file contents
	// the the physical memory region of the guest
	for (i = 0; i < memsz; i += PGSIZE) {
  8001fa:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%rbp)
  800201:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800204:	48 98                	cltq   
  800206:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  80020a:	0f 82 90 fe ff ff    	jb     8000a0 <map_in_guest+0x5d>
			return ret;
		}
		sys_page_unmap(0, UTEMP);
	}

	return 0;
  800210:	b8 00 00 00 00       	mov    $0x0,%eax
} 
  800215:	c9                   	leaveq 
  800216:	c3                   	retq   

0000000000800217 <copy_guest_kern_gpa>:
//
// Return 0 on success, <0 on error
//
// Hint: compare with ELF parsing in env.c, and use map_in_guest for each segment.
static int
copy_guest_kern_gpa( envid_t guest, char* fname ) {
  800217:	55                   	push   %rbp
  800218:	48 89 e5             	mov    %rsp,%rbp
  80021b:	41 57                	push   %r15
  80021d:	41 56                	push   %r14
  80021f:	41 55                	push   %r13
  800221:	41 54                	push   %r12
  800223:	53                   	push   %rbx
  800224:	48 83 ec 58          	sub    $0x58,%rsp
  800228:	89 7d 8c             	mov    %edi,-0x74(%rbp)
  80022b:	48 89 75 80          	mov    %rsi,-0x80(%rbp)
  80022f:	48 89 e0             	mov    %rsp,%rax
  800232:	48 89 c3             	mov    %rax,%rbx
	// open the specified file
	int fd, i, ret;
	fd = open(fname, O_RDONLY);
  800235:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  800239:	be 00 00 00 00       	mov    $0x0,%esi
  80023e:	48 89 c7             	mov    %rax,%rdi
  800241:	48 b8 7b 2a 80 00 00 	movabs $0x802a7b,%rax
  800248:	00 00 00 
  80024b:	ff d0                	callq  *%rax
  80024d:	89 45 bc             	mov    %eax,-0x44(%rbp)
	if (fd < 0) {
  800250:	83 7d bc 00          	cmpl   $0x0,-0x44(%rbp)
  800254:	79 2d                	jns    800283 <copy_guest_kern_gpa+0x6c>
		cprintf("error opening %s: %e\n", fname, fd);
  800256:	8b 55 bc             	mov    -0x44(%rbp),%edx
  800259:	48 8b 45 80          	mov    -0x80(%rbp),%rax
  80025d:	48 89 c6             	mov    %rax,%rsi
  800260:	48 bf c0 45 80 00 00 	movabs $0x8045c0,%rdi
  800267:	00 00 00 
  80026a:	b8 00 00 00 00       	mov    $0x0,%eax
  80026f:	48 b9 c9 07 80 00 00 	movabs $0x8007c9,%rcx
  800276:	00 00 00 
  800279:	ff d1                	callq  *%rcx
		return fd;
  80027b:	8b 45 bc             	mov    -0x44(%rbp),%eax
  80027e:	e9 d5 01 00 00       	jmpq   800458 <copy_guest_kern_gpa+0x241>
	}

	int buflen = 512; // large enough to fit the whole Elf struct
  800283:	c7 45 b8 00 02 00 00 	movl   $0x200,-0x48(%rbp)
	unsigned char elf_buf[buflen];
  80028a:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80028d:	48 63 d0             	movslq %eax,%rdx
  800290:	48 83 ea 01          	sub    $0x1,%rdx
  800294:	48 89 55 b0          	mov    %rdx,-0x50(%rbp)
  800298:	48 63 d0             	movslq %eax,%rdx
  80029b:	49 89 d6             	mov    %rdx,%r14
  80029e:	41 bf 00 00 00 00    	mov    $0x0,%r15d
  8002a4:	48 63 d0             	movslq %eax,%rdx
  8002a7:	49 89 d4             	mov    %rdx,%r12
  8002aa:	41 bd 00 00 00 00    	mov    $0x0,%r13d
  8002b0:	48 98                	cltq   
  8002b2:	ba 10 00 00 00       	mov    $0x10,%edx
  8002b7:	48 83 ea 01          	sub    $0x1,%rdx
  8002bb:	48 01 d0             	add    %rdx,%rax
  8002be:	b9 10 00 00 00       	mov    $0x10,%ecx
  8002c3:	ba 00 00 00 00       	mov    $0x0,%edx
  8002c8:	48 f7 f1             	div    %rcx
  8002cb:	48 6b c0 10          	imul   $0x10,%rax,%rax
  8002cf:	48 29 c4             	sub    %rax,%rsp
  8002d2:	48 89 e0             	mov    %rsp,%rax
  8002d5:	48 83 c0 00          	add    $0x0,%rax
  8002d9:	48 89 45 a8          	mov    %rax,-0x58(%rbp)
	struct Elf *elf;
	struct Proghdr *ph;

	// read in the header of file fname
	ret = readn(fd, elf_buf, buflen);
  8002dd:	8b 45 b8             	mov    -0x48(%rbp),%eax
  8002e0:	48 63 d0             	movslq %eax,%rdx
  8002e3:	48 8b 4d a8          	mov    -0x58(%rbp),%rcx
  8002e7:	8b 45 bc             	mov    -0x44(%rbp),%eax
  8002ea:	48 89 ce             	mov    %rcx,%rsi
  8002ed:	89 c7                	mov    %eax,%edi
  8002ef:	48 b8 7a 26 80 00 00 	movabs $0x80267a,%rax
  8002f6:	00 00 00 
  8002f9:	ff d0                	callq  *%rax
  8002fb:	89 45 a4             	mov    %eax,-0x5c(%rbp)
	if (ret != buflen) {
  8002fe:	8b 45 a4             	mov    -0x5c(%rbp),%eax
  800301:	3b 45 b8             	cmp    -0x48(%rbp),%eax
  800304:	74 36                	je     80033c <copy_guest_kern_gpa+0x125>
		close(fd);
  800306:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800309:	89 c7                	mov    %eax,%edi
  80030b:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  800312:	00 00 00 
  800315:	ff d0                	callq  *%rax
		cprintf("Failed to read in ELF header\n");
  800317:	48 bf d6 45 80 00 00 	movabs $0x8045d6,%rdi
  80031e:	00 00 00 
  800321:	b8 00 00 00 00       	mov    $0x0,%eax
  800326:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  80032d:	00 00 00 
  800330:	ff d2                	callq  *%rdx
		return -E_NOT_EXEC;
  800332:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  800337:	e9 1c 01 00 00       	jmpq   800458 <copy_guest_kern_gpa+0x241>
	}

	// point the elf struct at the elf buf
	elf = (struct Elf*) elf_buf;
  80033c:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800340:	48 89 45 98          	mov    %rax,-0x68(%rbp)

	// check the ELF header's magic value to check that we are working with a valid ELF binary
	if (elf->e_magic != ELF_MAGIC) {
  800344:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800348:	8b 00                	mov    (%rax),%eax
  80034a:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  80034f:	74 39                	je     80038a <copy_guest_kern_gpa+0x173>
		close(fd);
  800351:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800354:	89 c7                	mov    %eax,%edi
  800356:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  80035d:	00 00 00 
  800360:	ff d0                	callq  *%rax
		cprintf("ELF magic is %08x, expected %08x\n", elf->e_magic, ELF_MAGIC);
  800362:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800366:	8b 00                	mov    (%rax),%eax
  800368:	ba 7f 45 4c 46       	mov    $0x464c457f,%edx
  80036d:	89 c6                	mov    %eax,%esi
  80036f:	48 bf f8 45 80 00 00 	movabs $0x8045f8,%rdi
  800376:	00 00 00 
  800379:	b8 00 00 00 00       	mov    $0x0,%eax
  80037e:	48 b9 c9 07 80 00 00 	movabs $0x8007c9,%rcx
  800385:	00 00 00 
  800388:	ff d1                	callq  *%rcx
	}

	// point the program header struct at the location indicated by the elf header
	ph = (struct Proghdr* ) (elf_buf + elf->e_phoff);
  80038a:	48 8b 55 a8          	mov    -0x58(%rbp),%rdx
  80038e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800392:	48 8b 40 20          	mov    0x20(%rax),%rax
  800396:	48 01 d0             	add    %rdx,%rax
  800399:	48 89 45 c0          	mov    %rax,-0x40(%rbp)

	// for every entry in the program header table, map the corresponding entry of the file 
	// into the guest's physical address space
	for (i = 0; i < elf->e_phnum; i++, ph++) {
  80039d:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%rbp)
  8003a4:	e9 85 00 00 00       	jmpq   80042e <copy_guest_kern_gpa+0x217>
		ret = map_in_guest(guest, ph->p_pa, ph->p_memsz, fd, ph->p_filesz, ph->p_offset);
  8003a9:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003ad:	48 8b 40 08          	mov    0x8(%rax),%rax
  8003b1:	41 89 c0             	mov    %eax,%r8d
  8003b4:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003b8:	48 8b 78 20          	mov    0x20(%rax),%rdi
  8003bc:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003c0:	48 8b 50 28          	mov    0x28(%rax),%rdx
  8003c4:	48 8b 45 c0          	mov    -0x40(%rbp),%rax
  8003c8:	48 8b 70 18          	mov    0x18(%rax),%rsi
  8003cc:	8b 4d bc             	mov    -0x44(%rbp),%ecx
  8003cf:	8b 45 8c             	mov    -0x74(%rbp),%eax
  8003d2:	45 89 c1             	mov    %r8d,%r9d
  8003d5:	49 89 f8             	mov    %rdi,%r8
  8003d8:	89 c7                	mov    %eax,%edi
  8003da:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  8003e1:	00 00 00 
  8003e4:	ff d0                	callq  *%rax
  8003e6:	89 45 a4             	mov    %eax,-0x5c(%rbp)
		if (ret < 0) {
  8003e9:	83 7d a4 00          	cmpl   $0x0,-0x5c(%rbp)
  8003ed:	79 36                	jns    800425 <copy_guest_kern_gpa+0x20e>
			cprintf("Error mapping EPT page in guest %e\n", ret);
  8003ef:	8b 45 a4             	mov    -0x5c(%rbp),%eax
  8003f2:	89 c6                	mov    %eax,%esi
  8003f4:	48 bf 20 46 80 00 00 	movabs $0x804620,%rdi
  8003fb:	00 00 00 
  8003fe:	b8 00 00 00 00       	mov    $0x0,%eax
  800403:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  80040a:	00 00 00 
  80040d:	ff d2                	callq  *%rdx
			close(fd);
  80040f:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800412:	89 c7                	mov    %eax,%edi
  800414:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  80041b:	00 00 00 
  80041e:	ff d0                	callq  *%rax
			return ret;
  800420:	8b 45 a4             	mov    -0x5c(%rbp),%eax
  800423:	eb 33                	jmp    800458 <copy_guest_kern_gpa+0x241>
	// point the program header struct at the location indicated by the elf header
	ph = (struct Proghdr* ) (elf_buf + elf->e_phoff);

	// for every entry in the program header table, map the corresponding entry of the file 
	// into the guest's physical address space
	for (i = 0; i < elf->e_phnum; i++, ph++) {
  800425:	83 45 cc 01          	addl   $0x1,-0x34(%rbp)
  800429:	48 83 45 c0 38       	addq   $0x38,-0x40(%rbp)
  80042e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800432:	0f b7 40 38          	movzwl 0x38(%rax),%eax
  800436:	0f b7 c0             	movzwl %ax,%eax
  800439:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  80043c:	0f 8f 67 ff ff ff    	jg     8003a9 <copy_guest_kern_gpa+0x192>
			close(fd);
			return ret;
		}
	}

	close(fd);
  800442:	8b 45 bc             	mov    -0x44(%rbp),%eax
  800445:	89 c7                	mov    %eax,%edi
  800447:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  80044e:	00 00 00 
  800451:	ff d0                	callq  *%rax
	return 0;
  800453:	b8 00 00 00 00       	mov    $0x0,%eax
  800458:	48 89 dc             	mov    %rbx,%rsp
}
  80045b:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  80045f:	5b                   	pop    %rbx
  800460:	41 5c                	pop    %r12
  800462:	41 5d                	pop    %r13
  800464:	41 5e                	pop    %r14
  800466:	41 5f                	pop    %r15
  800468:	5d                   	pop    %rbp
  800469:	c3                   	retq   

000000000080046a <umain>:

void
umain(int argc, char **argv) {
  80046a:	55                   	push   %rbp
  80046b:	48 89 e5             	mov    %rsp,%rbp
  80046e:	48 83 ec 50          	sub    $0x50,%rsp
  800472:	89 7d bc             	mov    %edi,-0x44(%rbp)
  800475:	48 89 75 b0          	mov    %rsi,-0x50(%rbp)
	int ret;
	envid_t guest;
	char filename_buffer[50];	//buffer to save the path 
	int vmdisk_number;
	int r;
	if ((ret = sys_env_mkguest( GUEST_MEM_SZ, JOS_ENTRY )) < 0) {
  800479:	be 00 70 00 00       	mov    $0x7000,%esi
  80047e:	bf 00 00 00 01       	mov    $0x1000000,%edi
  800483:	48 b8 43 20 80 00 00 	movabs $0x802043,%rax
  80048a:	00 00 00 
  80048d:	ff d0                	callq  *%rax
  80048f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  800492:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800496:	79 2c                	jns    8004c4 <umain+0x5a>
		cprintf("Error creating a guest OS env: %e\n", ret );
  800498:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80049b:	89 c6                	mov    %eax,%esi
  80049d:	48 bf 48 46 80 00 00 	movabs $0x804648,%rdi
  8004a4:	00 00 00 
  8004a7:	b8 00 00 00 00       	mov    $0x0,%eax
  8004ac:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  8004b3:	00 00 00 
  8004b6:	ff d2                	callq  *%rdx
		exit();
  8004b8:	48 b8 81 06 80 00 00 	movabs $0x800681,%rax
  8004bf:	00 00 00 
  8004c2:	ff d0                	callq  *%rax
	}
	guest = ret;
  8004c4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004c7:	89 45 f8             	mov    %eax,-0x8(%rbp)

	// Copy the guest kernel code into guest phys mem.
	if((ret = copy_guest_kern_gpa(guest, GUEST_KERN)) < 0) {
  8004ca:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8004cd:	48 be 6b 46 80 00 00 	movabs $0x80466b,%rsi
  8004d4:	00 00 00 
  8004d7:	89 c7                	mov    %eax,%edi
  8004d9:	48 b8 17 02 80 00 00 	movabs $0x800217,%rax
  8004e0:	00 00 00 
  8004e3:	ff d0                	callq  *%rax
  8004e5:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004e8:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004ec:	79 2c                	jns    80051a <umain+0xb0>
		cprintf("Error copying page into the guest - %d\n.", ret);
  8004ee:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8004f1:	89 c6                	mov    %eax,%esi
  8004f3:	48 bf 78 46 80 00 00 	movabs $0x804678,%rdi
  8004fa:	00 00 00 
  8004fd:	b8 00 00 00 00       	mov    $0x0,%eax
  800502:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  800509:	00 00 00 
  80050c:	ff d2                	callq  *%rdx
		exit();
  80050e:	48 b8 81 06 80 00 00 	movabs $0x800681,%rax
  800515:	00 00 00 
  800518:	ff d0                	callq  *%rax
	}

	// Now copy the bootloader.
	int fd;
	if ((fd = open( GUEST_BOOT, O_RDONLY)) < 0 ) {
  80051a:	be 00 00 00 00       	mov    $0x0,%esi
  80051f:	48 bf a1 46 80 00 00 	movabs $0x8046a1,%rdi
  800526:	00 00 00 
  800529:	48 b8 7b 2a 80 00 00 	movabs $0x802a7b,%rax
  800530:	00 00 00 
  800533:	ff d0                	callq  *%rax
  800535:	89 45 f4             	mov    %eax,-0xc(%rbp)
  800538:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  80053c:	79 36                	jns    800574 <umain+0x10a>
		cprintf("open %s for read: %e\n", GUEST_BOOT, fd );
  80053e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  800541:	89 c2                	mov    %eax,%edx
  800543:	48 be a1 46 80 00 00 	movabs $0x8046a1,%rsi
  80054a:	00 00 00 
  80054d:	48 bf ab 46 80 00 00 	movabs $0x8046ab,%rdi
  800554:	00 00 00 
  800557:	b8 00 00 00 00       	mov    $0x0,%eax
  80055c:	48 b9 c9 07 80 00 00 	movabs $0x8007c9,%rcx
  800563:	00 00 00 
  800566:	ff d1                	callq  *%rcx
		exit();
  800568:	48 b8 81 06 80 00 00 	movabs $0x800681,%rax
  80056f:	00 00 00 
  800572:	ff d0                	callq  *%rax
	}

	// sizeof(bootloader) < 512.
	if ((ret = map_in_guest(guest, JOS_ENTRY, 512, fd, 512, 0)) < 0) {
  800574:	8b 55 f4             	mov    -0xc(%rbp),%edx
  800577:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80057a:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  800580:	41 b8 00 02 00 00    	mov    $0x200,%r8d
  800586:	89 d1                	mov    %edx,%ecx
  800588:	ba 00 02 00 00       	mov    $0x200,%edx
  80058d:	be 00 70 00 00       	mov    $0x7000,%esi
  800592:	89 c7                	mov    %eax,%edi
  800594:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  80059b:	00 00 00 
  80059e:	ff d0                	callq  *%rax
  8005a0:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8005a3:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8005a7:	79 2c                	jns    8005d5 <umain+0x16b>
		cprintf("Error mapping bootloader into the guest - %d\n.", ret);
  8005a9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8005ac:	89 c6                	mov    %eax,%esi
  8005ae:	48 bf c8 46 80 00 00 	movabs $0x8046c8,%rdi
  8005b5:	00 00 00 
  8005b8:	b8 00 00 00 00       	mov    $0x0,%eax
  8005bd:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  8005c4:	00 00 00 
  8005c7:	ff d2                	callq  *%rdx
		exit();
  8005c9:	48 b8 81 06 80 00 00 	movabs $0x800681,%rax
  8005d0:	00 00 00 
  8005d3:	ff d0                	callq  *%rax
        }
        
        cprintf("Create VHD finished\n");
#endif
	// Mark the guest as runnable.
	sys_env_set_status(guest, ENV_RUNNABLE);
  8005d5:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8005d8:	be 02 00 00 00       	mov    $0x2,%esi
  8005dd:	89 c7                	mov    %eax,%edi
  8005df:	48 b8 a2 1d 80 00 00 	movabs $0x801da2,%rax
  8005e6:	00 00 00 
  8005e9:	ff d0                	callq  *%rax
	wait(guest);
  8005eb:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8005ee:	89 c7                	mov    %eax,%edi
  8005f0:	48 b8 8d 3e 80 00 00 	movabs $0x803e8d,%rax
  8005f7:	00 00 00 
  8005fa:	ff d0                	callq  *%rax
}
  8005fc:	c9                   	leaveq 
  8005fd:	c3                   	retq   

00000000008005fe <libmain>:
  8005fe:	55                   	push   %rbp
  8005ff:	48 89 e5             	mov    %rsp,%rbp
  800602:	48 83 ec 10          	sub    $0x10,%rsp
  800606:	89 7d fc             	mov    %edi,-0x4(%rbp)
  800609:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80060d:	48 b8 31 1c 80 00 00 	movabs $0x801c31,%rax
  800614:	00 00 00 
  800617:	ff d0                	callq  *%rax
  800619:	25 ff 03 00 00       	and    $0x3ff,%eax
  80061e:	48 98                	cltq   
  800620:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  800627:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  80062e:	00 00 00 
  800631:	48 01 c2             	add    %rax,%rdx
  800634:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  80063b:	00 00 00 
  80063e:	48 89 10             	mov    %rdx,(%rax)
  800641:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800645:	7e 14                	jle    80065b <libmain+0x5d>
  800647:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80064b:	48 8b 10             	mov    (%rax),%rdx
  80064e:	48 b8 00 60 80 00 00 	movabs $0x806000,%rax
  800655:	00 00 00 
  800658:	48 89 10             	mov    %rdx,(%rax)
  80065b:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80065f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800662:	48 89 d6             	mov    %rdx,%rsi
  800665:	89 c7                	mov    %eax,%edi
  800667:	48 b8 6a 04 80 00 00 	movabs $0x80046a,%rax
  80066e:	00 00 00 
  800671:	ff d0                	callq  *%rax
  800673:	48 b8 81 06 80 00 00 	movabs $0x800681,%rax
  80067a:	00 00 00 
  80067d:	ff d0                	callq  *%rax
  80067f:	c9                   	leaveq 
  800680:	c3                   	retq   

0000000000800681 <exit>:
  800681:	55                   	push   %rbp
  800682:	48 89 e5             	mov    %rsp,%rbp
  800685:	48 b8 ce 23 80 00 00 	movabs $0x8023ce,%rax
  80068c:	00 00 00 
  80068f:	ff d0                	callq  *%rax
  800691:	bf 00 00 00 00       	mov    $0x0,%edi
  800696:	48 b8 ed 1b 80 00 00 	movabs $0x801bed,%rax
  80069d:	00 00 00 
  8006a0:	ff d0                	callq  *%rax
  8006a2:	5d                   	pop    %rbp
  8006a3:	c3                   	retq   

00000000008006a4 <putch>:
  8006a4:	55                   	push   %rbp
  8006a5:	48 89 e5             	mov    %rsp,%rbp
  8006a8:	48 83 ec 10          	sub    $0x10,%rsp
  8006ac:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8006af:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8006b3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8006b7:	8b 00                	mov    (%rax),%eax
  8006b9:	8d 48 01             	lea    0x1(%rax),%ecx
  8006bc:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8006c0:	89 0a                	mov    %ecx,(%rdx)
  8006c2:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8006c5:	89 d1                	mov    %edx,%ecx
  8006c7:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8006cb:	48 98                	cltq   
  8006cd:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  8006d1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8006d5:	8b 00                	mov    (%rax),%eax
  8006d7:	3d ff 00 00 00       	cmp    $0xff,%eax
  8006dc:	75 2c                	jne    80070a <putch+0x66>
  8006de:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8006e2:	8b 00                	mov    (%rax),%eax
  8006e4:	48 98                	cltq   
  8006e6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8006ea:	48 83 c2 08          	add    $0x8,%rdx
  8006ee:	48 89 c6             	mov    %rax,%rsi
  8006f1:	48 89 d7             	mov    %rdx,%rdi
  8006f4:	48 b8 65 1b 80 00 00 	movabs $0x801b65,%rax
  8006fb:	00 00 00 
  8006fe:	ff d0                	callq  *%rax
  800700:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800704:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  80070a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80070e:	8b 40 04             	mov    0x4(%rax),%eax
  800711:	8d 50 01             	lea    0x1(%rax),%edx
  800714:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800718:	89 50 04             	mov    %edx,0x4(%rax)
  80071b:	c9                   	leaveq 
  80071c:	c3                   	retq   

000000000080071d <vcprintf>:
  80071d:	55                   	push   %rbp
  80071e:	48 89 e5             	mov    %rsp,%rbp
  800721:	48 81 ec 40 01 00 00 	sub    $0x140,%rsp
  800728:	48 89 bd c8 fe ff ff 	mov    %rdi,-0x138(%rbp)
  80072f:	48 89 b5 c0 fe ff ff 	mov    %rsi,-0x140(%rbp)
  800736:	48 8d 85 d8 fe ff ff 	lea    -0x128(%rbp),%rax
  80073d:	48 8b 95 c0 fe ff ff 	mov    -0x140(%rbp),%rdx
  800744:	48 8b 0a             	mov    (%rdx),%rcx
  800747:	48 89 08             	mov    %rcx,(%rax)
  80074a:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  80074e:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800752:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  800756:	48 89 50 10          	mov    %rdx,0x10(%rax)
  80075a:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%rbp)
  800761:	00 00 00 
  800764:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%rbp)
  80076b:	00 00 00 
  80076e:	48 8d 8d d8 fe ff ff 	lea    -0x128(%rbp),%rcx
  800775:	48 8b 95 c8 fe ff ff 	mov    -0x138(%rbp),%rdx
  80077c:	48 8d 85 f0 fe ff ff 	lea    -0x110(%rbp),%rax
  800783:	48 89 c6             	mov    %rax,%rsi
  800786:	48 bf a4 06 80 00 00 	movabs $0x8006a4,%rdi
  80078d:	00 00 00 
  800790:	48 b8 7c 0b 80 00 00 	movabs $0x800b7c,%rax
  800797:	00 00 00 
  80079a:	ff d0                	callq  *%rax
  80079c:	8b 85 f0 fe ff ff    	mov    -0x110(%rbp),%eax
  8007a2:	48 98                	cltq   
  8007a4:	48 8d 95 f0 fe ff ff 	lea    -0x110(%rbp),%rdx
  8007ab:	48 83 c2 08          	add    $0x8,%rdx
  8007af:	48 89 c6             	mov    %rax,%rsi
  8007b2:	48 89 d7             	mov    %rdx,%rdi
  8007b5:	48 b8 65 1b 80 00 00 	movabs $0x801b65,%rax
  8007bc:	00 00 00 
  8007bf:	ff d0                	callq  *%rax
  8007c1:	8b 85 f4 fe ff ff    	mov    -0x10c(%rbp),%eax
  8007c7:	c9                   	leaveq 
  8007c8:	c3                   	retq   

00000000008007c9 <cprintf>:
  8007c9:	55                   	push   %rbp
  8007ca:	48 89 e5             	mov    %rsp,%rbp
  8007cd:	48 81 ec 00 01 00 00 	sub    $0x100,%rsp
  8007d4:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
  8007db:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
  8007e2:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8007e9:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8007f0:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  8007f7:	84 c0                	test   %al,%al
  8007f9:	74 20                	je     80081b <cprintf+0x52>
  8007fb:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8007ff:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  800803:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  800807:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  80080b:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  80080f:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  800813:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  800817:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  80081b:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  800822:	c7 85 30 ff ff ff 08 	movl   $0x8,-0xd0(%rbp)
  800829:	00 00 00 
  80082c:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  800833:	00 00 00 
  800836:	48 8d 45 10          	lea    0x10(%rbp),%rax
  80083a:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  800841:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  800848:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  80084f:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  800856:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  80085d:	48 8b 0a             	mov    (%rdx),%rcx
  800860:	48 89 08             	mov    %rcx,(%rax)
  800863:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800867:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80086b:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80086f:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800873:	48 8d 95 18 ff ff ff 	lea    -0xe8(%rbp),%rdx
  80087a:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  800881:	48 89 d6             	mov    %rdx,%rsi
  800884:	48 89 c7             	mov    %rax,%rdi
  800887:	48 b8 1d 07 80 00 00 	movabs $0x80071d,%rax
  80088e:	00 00 00 
  800891:	ff d0                	callq  *%rax
  800893:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  800899:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  80089f:	c9                   	leaveq 
  8008a0:	c3                   	retq   

00000000008008a1 <printnum>:
  8008a1:	55                   	push   %rbp
  8008a2:	48 89 e5             	mov    %rsp,%rbp
  8008a5:	53                   	push   %rbx
  8008a6:	48 83 ec 38          	sub    $0x38,%rsp
  8008aa:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8008ae:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8008b2:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8008b6:	89 4d d4             	mov    %ecx,-0x2c(%rbp)
  8008b9:	44 89 45 d0          	mov    %r8d,-0x30(%rbp)
  8008bd:	44 89 4d cc          	mov    %r9d,-0x34(%rbp)
  8008c1:	8b 45 d4             	mov    -0x2c(%rbp),%eax
  8008c4:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8008c8:	77 3b                	ja     800905 <printnum+0x64>
  8008ca:	8b 45 d0             	mov    -0x30(%rbp),%eax
  8008cd:	44 8d 40 ff          	lea    -0x1(%rax),%r8d
  8008d1:	8b 5d d4             	mov    -0x2c(%rbp),%ebx
  8008d4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8008d8:	ba 00 00 00 00       	mov    $0x0,%edx
  8008dd:	48 f7 f3             	div    %rbx
  8008e0:	48 89 c2             	mov    %rax,%rdx
  8008e3:	8b 7d cc             	mov    -0x34(%rbp),%edi
  8008e6:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  8008e9:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
  8008ed:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8008f1:	41 89 f9             	mov    %edi,%r9d
  8008f4:	48 89 c7             	mov    %rax,%rdi
  8008f7:	48 b8 a1 08 80 00 00 	movabs $0x8008a1,%rax
  8008fe:	00 00 00 
  800901:	ff d0                	callq  *%rax
  800903:	eb 1e                	jmp    800923 <printnum+0x82>
  800905:	eb 12                	jmp    800919 <printnum+0x78>
  800907:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  80090b:	8b 55 cc             	mov    -0x34(%rbp),%edx
  80090e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800912:	48 89 ce             	mov    %rcx,%rsi
  800915:	89 d7                	mov    %edx,%edi
  800917:	ff d0                	callq  *%rax
  800919:	83 6d d0 01          	subl   $0x1,-0x30(%rbp)
  80091d:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
  800921:	7f e4                	jg     800907 <printnum+0x66>
  800923:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  800926:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80092a:	ba 00 00 00 00       	mov    $0x0,%edx
  80092f:	48 f7 f1             	div    %rcx
  800932:	48 89 d0             	mov    %rdx,%rax
  800935:	48 ba 10 49 80 00 00 	movabs $0x804910,%rdx
  80093c:	00 00 00 
  80093f:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  800943:	0f be d0             	movsbl %al,%edx
  800946:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  80094a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80094e:	48 89 ce             	mov    %rcx,%rsi
  800951:	89 d7                	mov    %edx,%edi
  800953:	ff d0                	callq  *%rax
  800955:	48 83 c4 38          	add    $0x38,%rsp
  800959:	5b                   	pop    %rbx
  80095a:	5d                   	pop    %rbp
  80095b:	c3                   	retq   

000000000080095c <getuint>:
  80095c:	55                   	push   %rbp
  80095d:	48 89 e5             	mov    %rsp,%rbp
  800960:	48 83 ec 1c          	sub    $0x1c,%rsp
  800964:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800968:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  80096b:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  80096f:	7e 52                	jle    8009c3 <getuint+0x67>
  800971:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800975:	8b 00                	mov    (%rax),%eax
  800977:	83 f8 30             	cmp    $0x30,%eax
  80097a:	73 24                	jae    8009a0 <getuint+0x44>
  80097c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800980:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800984:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800988:	8b 00                	mov    (%rax),%eax
  80098a:	89 c0                	mov    %eax,%eax
  80098c:	48 01 d0             	add    %rdx,%rax
  80098f:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800993:	8b 12                	mov    (%rdx),%edx
  800995:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800998:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80099c:	89 0a                	mov    %ecx,(%rdx)
  80099e:	eb 17                	jmp    8009b7 <getuint+0x5b>
  8009a0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8009a4:	48 8b 50 08          	mov    0x8(%rax),%rdx
  8009a8:	48 89 d0             	mov    %rdx,%rax
  8009ab:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  8009af:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8009b3:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  8009b7:	48 8b 00             	mov    (%rax),%rax
  8009ba:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8009be:	e9 a3 00 00 00       	jmpq   800a66 <getuint+0x10a>
  8009c3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  8009c7:	74 4f                	je     800a18 <getuint+0xbc>
  8009c9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8009cd:	8b 00                	mov    (%rax),%eax
  8009cf:	83 f8 30             	cmp    $0x30,%eax
  8009d2:	73 24                	jae    8009f8 <getuint+0x9c>
  8009d4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8009d8:	48 8b 50 10          	mov    0x10(%rax),%rdx
  8009dc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8009e0:	8b 00                	mov    (%rax),%eax
  8009e2:	89 c0                	mov    %eax,%eax
  8009e4:	48 01 d0             	add    %rdx,%rax
  8009e7:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8009eb:	8b 12                	mov    (%rdx),%edx
  8009ed:	8d 4a 08             	lea    0x8(%rdx),%ecx
  8009f0:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8009f4:	89 0a                	mov    %ecx,(%rdx)
  8009f6:	eb 17                	jmp    800a0f <getuint+0xb3>
  8009f8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8009fc:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800a00:	48 89 d0             	mov    %rdx,%rax
  800a03:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800a07:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800a0b:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800a0f:	48 8b 00             	mov    (%rax),%rax
  800a12:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800a16:	eb 4e                	jmp    800a66 <getuint+0x10a>
  800a18:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a1c:	8b 00                	mov    (%rax),%eax
  800a1e:	83 f8 30             	cmp    $0x30,%eax
  800a21:	73 24                	jae    800a47 <getuint+0xeb>
  800a23:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a27:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800a2b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a2f:	8b 00                	mov    (%rax),%eax
  800a31:	89 c0                	mov    %eax,%eax
  800a33:	48 01 d0             	add    %rdx,%rax
  800a36:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800a3a:	8b 12                	mov    (%rdx),%edx
  800a3c:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800a3f:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800a43:	89 0a                	mov    %ecx,(%rdx)
  800a45:	eb 17                	jmp    800a5e <getuint+0x102>
  800a47:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a4b:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800a4f:	48 89 d0             	mov    %rdx,%rax
  800a52:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800a56:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800a5a:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800a5e:	8b 00                	mov    (%rax),%eax
  800a60:	89 c0                	mov    %eax,%eax
  800a62:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800a66:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800a6a:	c9                   	leaveq 
  800a6b:	c3                   	retq   

0000000000800a6c <getint>:
  800a6c:	55                   	push   %rbp
  800a6d:	48 89 e5             	mov    %rsp,%rbp
  800a70:	48 83 ec 1c          	sub    $0x1c,%rsp
  800a74:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800a78:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800a7b:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800a7f:	7e 52                	jle    800ad3 <getint+0x67>
  800a81:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a85:	8b 00                	mov    (%rax),%eax
  800a87:	83 f8 30             	cmp    $0x30,%eax
  800a8a:	73 24                	jae    800ab0 <getint+0x44>
  800a8c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a90:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800a94:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800a98:	8b 00                	mov    (%rax),%eax
  800a9a:	89 c0                	mov    %eax,%eax
  800a9c:	48 01 d0             	add    %rdx,%rax
  800a9f:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800aa3:	8b 12                	mov    (%rdx),%edx
  800aa5:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800aa8:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800aac:	89 0a                	mov    %ecx,(%rdx)
  800aae:	eb 17                	jmp    800ac7 <getint+0x5b>
  800ab0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ab4:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800ab8:	48 89 d0             	mov    %rdx,%rax
  800abb:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800abf:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800ac3:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800ac7:	48 8b 00             	mov    (%rax),%rax
  800aca:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800ace:	e9 a3 00 00 00       	jmpq   800b76 <getint+0x10a>
  800ad3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800ad7:	74 4f                	je     800b28 <getint+0xbc>
  800ad9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800add:	8b 00                	mov    (%rax),%eax
  800adf:	83 f8 30             	cmp    $0x30,%eax
  800ae2:	73 24                	jae    800b08 <getint+0x9c>
  800ae4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ae8:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800aec:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800af0:	8b 00                	mov    (%rax),%eax
  800af2:	89 c0                	mov    %eax,%eax
  800af4:	48 01 d0             	add    %rdx,%rax
  800af7:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800afb:	8b 12                	mov    (%rdx),%edx
  800afd:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800b00:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b04:	89 0a                	mov    %ecx,(%rdx)
  800b06:	eb 17                	jmp    800b1f <getint+0xb3>
  800b08:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b0c:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800b10:	48 89 d0             	mov    %rdx,%rax
  800b13:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800b17:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b1b:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800b1f:	48 8b 00             	mov    (%rax),%rax
  800b22:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800b26:	eb 4e                	jmp    800b76 <getint+0x10a>
  800b28:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b2c:	8b 00                	mov    (%rax),%eax
  800b2e:	83 f8 30             	cmp    $0x30,%eax
  800b31:	73 24                	jae    800b57 <getint+0xeb>
  800b33:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b37:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800b3b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b3f:	8b 00                	mov    (%rax),%eax
  800b41:	89 c0                	mov    %eax,%eax
  800b43:	48 01 d0             	add    %rdx,%rax
  800b46:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b4a:	8b 12                	mov    (%rdx),%edx
  800b4c:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800b4f:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b53:	89 0a                	mov    %ecx,(%rdx)
  800b55:	eb 17                	jmp    800b6e <getint+0x102>
  800b57:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b5b:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800b5f:	48 89 d0             	mov    %rdx,%rax
  800b62:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800b66:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800b6a:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800b6e:	8b 00                	mov    (%rax),%eax
  800b70:	48 98                	cltq   
  800b72:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800b76:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800b7a:	c9                   	leaveq 
  800b7b:	c3                   	retq   

0000000000800b7c <vprintfmt>:
  800b7c:	55                   	push   %rbp
  800b7d:	48 89 e5             	mov    %rsp,%rbp
  800b80:	41 54                	push   %r12
  800b82:	53                   	push   %rbx
  800b83:	48 83 ec 60          	sub    $0x60,%rsp
  800b87:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
  800b8b:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  800b8f:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800b93:	48 89 4d 90          	mov    %rcx,-0x70(%rbp)
  800b97:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800b9b:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  800b9f:	48 8b 0a             	mov    (%rdx),%rcx
  800ba2:	48 89 08             	mov    %rcx,(%rax)
  800ba5:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800ba9:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800bad:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  800bb1:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800bb5:	eb 17                	jmp    800bce <vprintfmt+0x52>
  800bb7:	85 db                	test   %ebx,%ebx
  800bb9:	0f 84 cc 04 00 00    	je     80108b <vprintfmt+0x50f>
  800bbf:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800bc3:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800bc7:	48 89 d6             	mov    %rdx,%rsi
  800bca:	89 df                	mov    %ebx,%edi
  800bcc:	ff d0                	callq  *%rax
  800bce:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800bd2:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800bd6:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800bda:	0f b6 00             	movzbl (%rax),%eax
  800bdd:	0f b6 d8             	movzbl %al,%ebx
  800be0:	83 fb 25             	cmp    $0x25,%ebx
  800be3:	75 d2                	jne    800bb7 <vprintfmt+0x3b>
  800be5:	c6 45 d3 20          	movb   $0x20,-0x2d(%rbp)
  800be9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%rbp)
  800bf0:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800bf7:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  800bfe:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  800c05:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800c09:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800c0d:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800c11:	0f b6 00             	movzbl (%rax),%eax
  800c14:	0f b6 d8             	movzbl %al,%ebx
  800c17:	8d 43 dd             	lea    -0x23(%rbx),%eax
  800c1a:	83 f8 55             	cmp    $0x55,%eax
  800c1d:	0f 87 34 04 00 00    	ja     801057 <vprintfmt+0x4db>
  800c23:	89 c0                	mov    %eax,%eax
  800c25:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  800c2c:	00 
  800c2d:	48 b8 38 49 80 00 00 	movabs $0x804938,%rax
  800c34:	00 00 00 
  800c37:	48 01 d0             	add    %rdx,%rax
  800c3a:	48 8b 00             	mov    (%rax),%rax
  800c3d:	ff e0                	jmpq   *%rax
  800c3f:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%rbp)
  800c43:	eb c0                	jmp    800c05 <vprintfmt+0x89>
  800c45:	c6 45 d3 30          	movb   $0x30,-0x2d(%rbp)
  800c49:	eb ba                	jmp    800c05 <vprintfmt+0x89>
  800c4b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  800c52:	8b 55 d8             	mov    -0x28(%rbp),%edx
  800c55:	89 d0                	mov    %edx,%eax
  800c57:	c1 e0 02             	shl    $0x2,%eax
  800c5a:	01 d0                	add    %edx,%eax
  800c5c:	01 c0                	add    %eax,%eax
  800c5e:	01 d8                	add    %ebx,%eax
  800c60:	83 e8 30             	sub    $0x30,%eax
  800c63:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800c66:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800c6a:	0f b6 00             	movzbl (%rax),%eax
  800c6d:	0f be d8             	movsbl %al,%ebx
  800c70:	83 fb 2f             	cmp    $0x2f,%ebx
  800c73:	7e 0c                	jle    800c81 <vprintfmt+0x105>
  800c75:	83 fb 39             	cmp    $0x39,%ebx
  800c78:	7f 07                	jg     800c81 <vprintfmt+0x105>
  800c7a:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
  800c7f:	eb d1                	jmp    800c52 <vprintfmt+0xd6>
  800c81:	eb 58                	jmp    800cdb <vprintfmt+0x15f>
  800c83:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800c86:	83 f8 30             	cmp    $0x30,%eax
  800c89:	73 17                	jae    800ca2 <vprintfmt+0x126>
  800c8b:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800c8f:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800c92:	89 c0                	mov    %eax,%eax
  800c94:	48 01 d0             	add    %rdx,%rax
  800c97:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800c9a:	83 c2 08             	add    $0x8,%edx
  800c9d:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800ca0:	eb 0f                	jmp    800cb1 <vprintfmt+0x135>
  800ca2:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800ca6:	48 89 d0             	mov    %rdx,%rax
  800ca9:	48 83 c2 08          	add    $0x8,%rdx
  800cad:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800cb1:	8b 00                	mov    (%rax),%eax
  800cb3:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800cb6:	eb 23                	jmp    800cdb <vprintfmt+0x15f>
  800cb8:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800cbc:	79 0c                	jns    800cca <vprintfmt+0x14e>
  800cbe:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%rbp)
  800cc5:	e9 3b ff ff ff       	jmpq   800c05 <vprintfmt+0x89>
  800cca:	e9 36 ff ff ff       	jmpq   800c05 <vprintfmt+0x89>
  800ccf:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
  800cd6:	e9 2a ff ff ff       	jmpq   800c05 <vprintfmt+0x89>
  800cdb:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800cdf:	79 12                	jns    800cf3 <vprintfmt+0x177>
  800ce1:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800ce4:	89 45 dc             	mov    %eax,-0x24(%rbp)
  800ce7:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800cee:	e9 12 ff ff ff       	jmpq   800c05 <vprintfmt+0x89>
  800cf3:	e9 0d ff ff ff       	jmpq   800c05 <vprintfmt+0x89>
  800cf8:	83 45 e0 01          	addl   $0x1,-0x20(%rbp)
  800cfc:	e9 04 ff ff ff       	jmpq   800c05 <vprintfmt+0x89>
  800d01:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800d04:	83 f8 30             	cmp    $0x30,%eax
  800d07:	73 17                	jae    800d20 <vprintfmt+0x1a4>
  800d09:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800d0d:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800d10:	89 c0                	mov    %eax,%eax
  800d12:	48 01 d0             	add    %rdx,%rax
  800d15:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800d18:	83 c2 08             	add    $0x8,%edx
  800d1b:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800d1e:	eb 0f                	jmp    800d2f <vprintfmt+0x1b3>
  800d20:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800d24:	48 89 d0             	mov    %rdx,%rax
  800d27:	48 83 c2 08          	add    $0x8,%rdx
  800d2b:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800d2f:	8b 10                	mov    (%rax),%edx
  800d31:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  800d35:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800d39:	48 89 ce             	mov    %rcx,%rsi
  800d3c:	89 d7                	mov    %edx,%edi
  800d3e:	ff d0                	callq  *%rax
  800d40:	e9 40 03 00 00       	jmpq   801085 <vprintfmt+0x509>
  800d45:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800d48:	83 f8 30             	cmp    $0x30,%eax
  800d4b:	73 17                	jae    800d64 <vprintfmt+0x1e8>
  800d4d:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800d51:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800d54:	89 c0                	mov    %eax,%eax
  800d56:	48 01 d0             	add    %rdx,%rax
  800d59:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800d5c:	83 c2 08             	add    $0x8,%edx
  800d5f:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800d62:	eb 0f                	jmp    800d73 <vprintfmt+0x1f7>
  800d64:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800d68:	48 89 d0             	mov    %rdx,%rax
  800d6b:	48 83 c2 08          	add    $0x8,%rdx
  800d6f:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800d73:	8b 18                	mov    (%rax),%ebx
  800d75:	85 db                	test   %ebx,%ebx
  800d77:	79 02                	jns    800d7b <vprintfmt+0x1ff>
  800d79:	f7 db                	neg    %ebx
  800d7b:	83 fb 15             	cmp    $0x15,%ebx
  800d7e:	7f 16                	jg     800d96 <vprintfmt+0x21a>
  800d80:	48 b8 60 48 80 00 00 	movabs $0x804860,%rax
  800d87:	00 00 00 
  800d8a:	48 63 d3             	movslq %ebx,%rdx
  800d8d:	4c 8b 24 d0          	mov    (%rax,%rdx,8),%r12
  800d91:	4d 85 e4             	test   %r12,%r12
  800d94:	75 2e                	jne    800dc4 <vprintfmt+0x248>
  800d96:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800d9a:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800d9e:	89 d9                	mov    %ebx,%ecx
  800da0:	48 ba 21 49 80 00 00 	movabs $0x804921,%rdx
  800da7:	00 00 00 
  800daa:	48 89 c7             	mov    %rax,%rdi
  800dad:	b8 00 00 00 00       	mov    $0x0,%eax
  800db2:	49 b8 94 10 80 00 00 	movabs $0x801094,%r8
  800db9:	00 00 00 
  800dbc:	41 ff d0             	callq  *%r8
  800dbf:	e9 c1 02 00 00       	jmpq   801085 <vprintfmt+0x509>
  800dc4:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800dc8:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800dcc:	4c 89 e1             	mov    %r12,%rcx
  800dcf:	48 ba 2a 49 80 00 00 	movabs $0x80492a,%rdx
  800dd6:	00 00 00 
  800dd9:	48 89 c7             	mov    %rax,%rdi
  800ddc:	b8 00 00 00 00       	mov    $0x0,%eax
  800de1:	49 b8 94 10 80 00 00 	movabs $0x801094,%r8
  800de8:	00 00 00 
  800deb:	41 ff d0             	callq  *%r8
  800dee:	e9 92 02 00 00       	jmpq   801085 <vprintfmt+0x509>
  800df3:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800df6:	83 f8 30             	cmp    $0x30,%eax
  800df9:	73 17                	jae    800e12 <vprintfmt+0x296>
  800dfb:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800dff:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800e02:	89 c0                	mov    %eax,%eax
  800e04:	48 01 d0             	add    %rdx,%rax
  800e07:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800e0a:	83 c2 08             	add    $0x8,%edx
  800e0d:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800e10:	eb 0f                	jmp    800e21 <vprintfmt+0x2a5>
  800e12:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800e16:	48 89 d0             	mov    %rdx,%rax
  800e19:	48 83 c2 08          	add    $0x8,%rdx
  800e1d:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800e21:	4c 8b 20             	mov    (%rax),%r12
  800e24:	4d 85 e4             	test   %r12,%r12
  800e27:	75 0a                	jne    800e33 <vprintfmt+0x2b7>
  800e29:	49 bc 2d 49 80 00 00 	movabs $0x80492d,%r12
  800e30:	00 00 00 
  800e33:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800e37:	7e 3f                	jle    800e78 <vprintfmt+0x2fc>
  800e39:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%rbp)
  800e3d:	74 39                	je     800e78 <vprintfmt+0x2fc>
  800e3f:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800e42:	48 98                	cltq   
  800e44:	48 89 c6             	mov    %rax,%rsi
  800e47:	4c 89 e7             	mov    %r12,%rdi
  800e4a:	48 b8 40 13 80 00 00 	movabs $0x801340,%rax
  800e51:	00 00 00 
  800e54:	ff d0                	callq  *%rax
  800e56:	29 45 dc             	sub    %eax,-0x24(%rbp)
  800e59:	eb 17                	jmp    800e72 <vprintfmt+0x2f6>
  800e5b:	0f be 55 d3          	movsbl -0x2d(%rbp),%edx
  800e5f:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  800e63:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800e67:	48 89 ce             	mov    %rcx,%rsi
  800e6a:	89 d7                	mov    %edx,%edi
  800e6c:	ff d0                	callq  *%rax
  800e6e:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800e72:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800e76:	7f e3                	jg     800e5b <vprintfmt+0x2df>
  800e78:	eb 37                	jmp    800eb1 <vprintfmt+0x335>
  800e7a:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
  800e7e:	74 1e                	je     800e9e <vprintfmt+0x322>
  800e80:	83 fb 1f             	cmp    $0x1f,%ebx
  800e83:	7e 05                	jle    800e8a <vprintfmt+0x30e>
  800e85:	83 fb 7e             	cmp    $0x7e,%ebx
  800e88:	7e 14                	jle    800e9e <vprintfmt+0x322>
  800e8a:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800e8e:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800e92:	48 89 d6             	mov    %rdx,%rsi
  800e95:	bf 3f 00 00 00       	mov    $0x3f,%edi
  800e9a:	ff d0                	callq  *%rax
  800e9c:	eb 0f                	jmp    800ead <vprintfmt+0x331>
  800e9e:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800ea2:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800ea6:	48 89 d6             	mov    %rdx,%rsi
  800ea9:	89 df                	mov    %ebx,%edi
  800eab:	ff d0                	callq  *%rax
  800ead:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800eb1:	4c 89 e0             	mov    %r12,%rax
  800eb4:	4c 8d 60 01          	lea    0x1(%rax),%r12
  800eb8:	0f b6 00             	movzbl (%rax),%eax
  800ebb:	0f be d8             	movsbl %al,%ebx
  800ebe:	85 db                	test   %ebx,%ebx
  800ec0:	74 10                	je     800ed2 <vprintfmt+0x356>
  800ec2:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  800ec6:	78 b2                	js     800e7a <vprintfmt+0x2fe>
  800ec8:	83 6d d8 01          	subl   $0x1,-0x28(%rbp)
  800ecc:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  800ed0:	79 a8                	jns    800e7a <vprintfmt+0x2fe>
  800ed2:	eb 16                	jmp    800eea <vprintfmt+0x36e>
  800ed4:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800ed8:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800edc:	48 89 d6             	mov    %rdx,%rsi
  800edf:	bf 20 00 00 00       	mov    $0x20,%edi
  800ee4:	ff d0                	callq  *%rax
  800ee6:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  800eea:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800eee:	7f e4                	jg     800ed4 <vprintfmt+0x358>
  800ef0:	e9 90 01 00 00       	jmpq   801085 <vprintfmt+0x509>
  800ef5:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800ef9:	be 03 00 00 00       	mov    $0x3,%esi
  800efe:	48 89 c7             	mov    %rax,%rdi
  800f01:	48 b8 6c 0a 80 00 00 	movabs $0x800a6c,%rax
  800f08:	00 00 00 
  800f0b:	ff d0                	callq  *%rax
  800f0d:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  800f11:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800f15:	48 85 c0             	test   %rax,%rax
  800f18:	79 1d                	jns    800f37 <vprintfmt+0x3bb>
  800f1a:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800f1e:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f22:	48 89 d6             	mov    %rdx,%rsi
  800f25:	bf 2d 00 00 00       	mov    $0x2d,%edi
  800f2a:	ff d0                	callq  *%rax
  800f2c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800f30:	48 f7 d8             	neg    %rax
  800f33:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  800f37:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  800f3e:	e9 d5 00 00 00       	jmpq   801018 <vprintfmt+0x49c>
  800f43:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800f47:	be 03 00 00 00       	mov    $0x3,%esi
  800f4c:	48 89 c7             	mov    %rax,%rdi
  800f4f:	48 b8 5c 09 80 00 00 	movabs $0x80095c,%rax
  800f56:	00 00 00 
  800f59:	ff d0                	callq  *%rax
  800f5b:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  800f5f:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  800f66:	e9 ad 00 00 00       	jmpq   801018 <vprintfmt+0x49c>
  800f6b:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800f6f:	be 03 00 00 00       	mov    $0x3,%esi
  800f74:	48 89 c7             	mov    %rax,%rdi
  800f77:	48 b8 5c 09 80 00 00 	movabs $0x80095c,%rax
  800f7e:	00 00 00 
  800f81:	ff d0                	callq  *%rax
  800f83:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  800f87:	c7 45 e4 08 00 00 00 	movl   $0x8,-0x1c(%rbp)
  800f8e:	e9 85 00 00 00       	jmpq   801018 <vprintfmt+0x49c>
  800f93:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800f97:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f9b:	48 89 d6             	mov    %rdx,%rsi
  800f9e:	bf 30 00 00 00       	mov    $0x30,%edi
  800fa3:	ff d0                	callq  *%rax
  800fa5:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800fa9:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800fad:	48 89 d6             	mov    %rdx,%rsi
  800fb0:	bf 78 00 00 00       	mov    $0x78,%edi
  800fb5:	ff d0                	callq  *%rax
  800fb7:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800fba:	83 f8 30             	cmp    $0x30,%eax
  800fbd:	73 17                	jae    800fd6 <vprintfmt+0x45a>
  800fbf:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800fc3:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800fc6:	89 c0                	mov    %eax,%eax
  800fc8:	48 01 d0             	add    %rdx,%rax
  800fcb:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800fce:	83 c2 08             	add    $0x8,%edx
  800fd1:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800fd4:	eb 0f                	jmp    800fe5 <vprintfmt+0x469>
  800fd6:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800fda:	48 89 d0             	mov    %rdx,%rax
  800fdd:	48 83 c2 08          	add    $0x8,%rdx
  800fe1:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800fe5:	48 8b 00             	mov    (%rax),%rax
  800fe8:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  800fec:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  800ff3:	eb 23                	jmp    801018 <vprintfmt+0x49c>
  800ff5:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800ff9:	be 03 00 00 00       	mov    $0x3,%esi
  800ffe:	48 89 c7             	mov    %rax,%rdi
  801001:	48 b8 5c 09 80 00 00 	movabs $0x80095c,%rax
  801008:	00 00 00 
  80100b:	ff d0                	callq  *%rax
  80100d:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801011:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  801018:	44 0f be 45 d3       	movsbl -0x2d(%rbp),%r8d
  80101d:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  801020:	8b 7d dc             	mov    -0x24(%rbp),%edi
  801023:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801027:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  80102b:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80102f:	45 89 c1             	mov    %r8d,%r9d
  801032:	41 89 f8             	mov    %edi,%r8d
  801035:	48 89 c7             	mov    %rax,%rdi
  801038:	48 b8 a1 08 80 00 00 	movabs $0x8008a1,%rax
  80103f:	00 00 00 
  801042:	ff d0                	callq  *%rax
  801044:	eb 3f                	jmp    801085 <vprintfmt+0x509>
  801046:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80104a:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80104e:	48 89 d6             	mov    %rdx,%rsi
  801051:	89 df                	mov    %ebx,%edi
  801053:	ff d0                	callq  *%rax
  801055:	eb 2e                	jmp    801085 <vprintfmt+0x509>
  801057:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  80105b:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80105f:	48 89 d6             	mov    %rdx,%rsi
  801062:	bf 25 00 00 00       	mov    $0x25,%edi
  801067:	ff d0                	callq  *%rax
  801069:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  80106e:	eb 05                	jmp    801075 <vprintfmt+0x4f9>
  801070:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  801075:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  801079:	48 83 e8 01          	sub    $0x1,%rax
  80107d:	0f b6 00             	movzbl (%rax),%eax
  801080:	3c 25                	cmp    $0x25,%al
  801082:	75 ec                	jne    801070 <vprintfmt+0x4f4>
  801084:	90                   	nop
  801085:	90                   	nop
  801086:	e9 43 fb ff ff       	jmpq   800bce <vprintfmt+0x52>
  80108b:	48 83 c4 60          	add    $0x60,%rsp
  80108f:	5b                   	pop    %rbx
  801090:	41 5c                	pop    %r12
  801092:	5d                   	pop    %rbp
  801093:	c3                   	retq   

0000000000801094 <printfmt>:
  801094:	55                   	push   %rbp
  801095:	48 89 e5             	mov    %rsp,%rbp
  801098:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  80109f:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  8010a6:	48 89 b5 20 ff ff ff 	mov    %rsi,-0xe0(%rbp)
  8010ad:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8010b4:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8010bb:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  8010c2:	84 c0                	test   %al,%al
  8010c4:	74 20                	je     8010e6 <printfmt+0x52>
  8010c6:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8010ca:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8010ce:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8010d2:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8010d6:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8010da:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8010de:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8010e2:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8010e6:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  8010ed:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  8010f4:	00 00 00 
  8010f7:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  8010fe:	00 00 00 
  801101:	48 8d 45 10          	lea    0x10(%rbp),%rax
  801105:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  80110c:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  801113:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
  80111a:	48 8d 8d 38 ff ff ff 	lea    -0xc8(%rbp),%rcx
  801121:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  801128:	48 8b b5 20 ff ff ff 	mov    -0xe0(%rbp),%rsi
  80112f:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  801136:	48 89 c7             	mov    %rax,%rdi
  801139:	48 b8 7c 0b 80 00 00 	movabs $0x800b7c,%rax
  801140:	00 00 00 
  801143:	ff d0                	callq  *%rax
  801145:	c9                   	leaveq 
  801146:	c3                   	retq   

0000000000801147 <sprintputch>:
  801147:	55                   	push   %rbp
  801148:	48 89 e5             	mov    %rsp,%rbp
  80114b:	48 83 ec 10          	sub    $0x10,%rsp
  80114f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801152:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801156:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80115a:	8b 40 10             	mov    0x10(%rax),%eax
  80115d:	8d 50 01             	lea    0x1(%rax),%edx
  801160:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801164:	89 50 10             	mov    %edx,0x10(%rax)
  801167:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80116b:	48 8b 10             	mov    (%rax),%rdx
  80116e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801172:	48 8b 40 08          	mov    0x8(%rax),%rax
  801176:	48 39 c2             	cmp    %rax,%rdx
  801179:	73 17                	jae    801192 <sprintputch+0x4b>
  80117b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80117f:	48 8b 00             	mov    (%rax),%rax
  801182:	48 8d 48 01          	lea    0x1(%rax),%rcx
  801186:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80118a:	48 89 0a             	mov    %rcx,(%rdx)
  80118d:	8b 55 fc             	mov    -0x4(%rbp),%edx
  801190:	88 10                	mov    %dl,(%rax)
  801192:	c9                   	leaveq 
  801193:	c3                   	retq   

0000000000801194 <vsnprintf>:
  801194:	55                   	push   %rbp
  801195:	48 89 e5             	mov    %rsp,%rbp
  801198:	48 83 ec 50          	sub    $0x50,%rsp
  80119c:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8011a0:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  8011a3:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  8011a7:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  8011ab:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
  8011af:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  8011b3:	48 8b 0a             	mov    (%rdx),%rcx
  8011b6:	48 89 08             	mov    %rcx,(%rax)
  8011b9:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8011bd:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8011c1:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8011c5:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8011c9:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8011cd:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
  8011d1:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  8011d4:	48 98                	cltq   
  8011d6:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  8011da:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  8011de:	48 01 d0             	add    %rdx,%rax
  8011e1:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  8011e5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  8011ec:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  8011f1:	74 06                	je     8011f9 <vsnprintf+0x65>
  8011f3:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  8011f7:	7f 07                	jg     801200 <vsnprintf+0x6c>
  8011f9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8011fe:	eb 2f                	jmp    80122f <vsnprintf+0x9b>
  801200:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  801204:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  801208:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  80120c:	48 89 c6             	mov    %rax,%rsi
  80120f:	48 bf 47 11 80 00 00 	movabs $0x801147,%rdi
  801216:	00 00 00 
  801219:	48 b8 7c 0b 80 00 00 	movabs $0x800b7c,%rax
  801220:	00 00 00 
  801223:	ff d0                	callq  *%rax
  801225:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801229:	c6 00 00             	movb   $0x0,(%rax)
  80122c:	8b 45 e0             	mov    -0x20(%rbp),%eax
  80122f:	c9                   	leaveq 
  801230:	c3                   	retq   

0000000000801231 <snprintf>:
  801231:	55                   	push   %rbp
  801232:	48 89 e5             	mov    %rsp,%rbp
  801235:	48 81 ec 10 01 00 00 	sub    $0x110,%rsp
  80123c:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  801243:	89 b5 04 ff ff ff    	mov    %esi,-0xfc(%rbp)
  801249:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  801250:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  801257:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80125e:	84 c0                	test   %al,%al
  801260:	74 20                	je     801282 <snprintf+0x51>
  801262:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  801266:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  80126a:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  80126e:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  801272:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  801276:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  80127a:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  80127e:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  801282:	48 89 95 f8 fe ff ff 	mov    %rdx,-0x108(%rbp)
  801289:	c7 85 30 ff ff ff 18 	movl   $0x18,-0xd0(%rbp)
  801290:	00 00 00 
  801293:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  80129a:	00 00 00 
  80129d:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8012a1:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  8012a8:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  8012af:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  8012b6:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  8012bd:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  8012c4:	48 8b 0a             	mov    (%rdx),%rcx
  8012c7:	48 89 08             	mov    %rcx,(%rax)
  8012ca:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8012ce:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8012d2:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8012d6:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8012da:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  8012e1:	48 8b 95 f8 fe ff ff 	mov    -0x108(%rbp),%rdx
  8012e8:	8b b5 04 ff ff ff    	mov    -0xfc(%rbp),%esi
  8012ee:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8012f5:	48 89 c7             	mov    %rax,%rdi
  8012f8:	48 b8 94 11 80 00 00 	movabs $0x801194,%rax
  8012ff:	00 00 00 
  801302:	ff d0                	callq  *%rax
  801304:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  80130a:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  801310:	c9                   	leaveq 
  801311:	c3                   	retq   

0000000000801312 <strlen>:
  801312:	55                   	push   %rbp
  801313:	48 89 e5             	mov    %rsp,%rbp
  801316:	48 83 ec 18          	sub    $0x18,%rsp
  80131a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80131e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  801325:	eb 09                	jmp    801330 <strlen+0x1e>
  801327:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80132b:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  801330:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801334:	0f b6 00             	movzbl (%rax),%eax
  801337:	84 c0                	test   %al,%al
  801339:	75 ec                	jne    801327 <strlen+0x15>
  80133b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80133e:	c9                   	leaveq 
  80133f:	c3                   	retq   

0000000000801340 <strnlen>:
  801340:	55                   	push   %rbp
  801341:	48 89 e5             	mov    %rsp,%rbp
  801344:	48 83 ec 20          	sub    $0x20,%rsp
  801348:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80134c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801350:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  801357:	eb 0e                	jmp    801367 <strnlen+0x27>
  801359:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80135d:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  801362:	48 83 6d e0 01       	subq   $0x1,-0x20(%rbp)
  801367:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  80136c:	74 0b                	je     801379 <strnlen+0x39>
  80136e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801372:	0f b6 00             	movzbl (%rax),%eax
  801375:	84 c0                	test   %al,%al
  801377:	75 e0                	jne    801359 <strnlen+0x19>
  801379:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80137c:	c9                   	leaveq 
  80137d:	c3                   	retq   

000000000080137e <strcpy>:
  80137e:	55                   	push   %rbp
  80137f:	48 89 e5             	mov    %rsp,%rbp
  801382:	48 83 ec 20          	sub    $0x20,%rsp
  801386:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80138a:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80138e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801392:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801396:	90                   	nop
  801397:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80139b:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80139f:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8013a3:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8013a7:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  8013ab:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  8013af:	0f b6 12             	movzbl (%rdx),%edx
  8013b2:	88 10                	mov    %dl,(%rax)
  8013b4:	0f b6 00             	movzbl (%rax),%eax
  8013b7:	84 c0                	test   %al,%al
  8013b9:	75 dc                	jne    801397 <strcpy+0x19>
  8013bb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8013bf:	c9                   	leaveq 
  8013c0:	c3                   	retq   

00000000008013c1 <strcat>:
  8013c1:	55                   	push   %rbp
  8013c2:	48 89 e5             	mov    %rsp,%rbp
  8013c5:	48 83 ec 20          	sub    $0x20,%rsp
  8013c9:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8013cd:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8013d1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8013d5:	48 89 c7             	mov    %rax,%rdi
  8013d8:	48 b8 12 13 80 00 00 	movabs $0x801312,%rax
  8013df:	00 00 00 
  8013e2:	ff d0                	callq  *%rax
  8013e4:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8013e7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8013ea:	48 63 d0             	movslq %eax,%rdx
  8013ed:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8013f1:	48 01 c2             	add    %rax,%rdx
  8013f4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8013f8:	48 89 c6             	mov    %rax,%rsi
  8013fb:	48 89 d7             	mov    %rdx,%rdi
  8013fe:	48 b8 7e 13 80 00 00 	movabs $0x80137e,%rax
  801405:	00 00 00 
  801408:	ff d0                	callq  *%rax
  80140a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80140e:	c9                   	leaveq 
  80140f:	c3                   	retq   

0000000000801410 <strncpy>:
  801410:	55                   	push   %rbp
  801411:	48 89 e5             	mov    %rsp,%rbp
  801414:	48 83 ec 28          	sub    $0x28,%rsp
  801418:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80141c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801420:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801424:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801428:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80142c:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  801433:	00 
  801434:	eb 2a                	jmp    801460 <strncpy+0x50>
  801436:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80143a:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80143e:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801442:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  801446:	0f b6 12             	movzbl (%rdx),%edx
  801449:	88 10                	mov    %dl,(%rax)
  80144b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80144f:	0f b6 00             	movzbl (%rax),%eax
  801452:	84 c0                	test   %al,%al
  801454:	74 05                	je     80145b <strncpy+0x4b>
  801456:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
  80145b:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801460:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801464:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  801468:	72 cc                	jb     801436 <strncpy+0x26>
  80146a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80146e:	c9                   	leaveq 
  80146f:	c3                   	retq   

0000000000801470 <strlcpy>:
  801470:	55                   	push   %rbp
  801471:	48 89 e5             	mov    %rsp,%rbp
  801474:	48 83 ec 28          	sub    $0x28,%rsp
  801478:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80147c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801480:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801484:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801488:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80148c:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  801491:	74 3d                	je     8014d0 <strlcpy+0x60>
  801493:	eb 1d                	jmp    8014b2 <strlcpy+0x42>
  801495:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801499:	48 8d 50 01          	lea    0x1(%rax),%rdx
  80149d:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8014a1:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8014a5:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  8014a9:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  8014ad:	0f b6 12             	movzbl (%rdx),%edx
  8014b0:	88 10                	mov    %dl,(%rax)
  8014b2:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  8014b7:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8014bc:	74 0b                	je     8014c9 <strlcpy+0x59>
  8014be:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8014c2:	0f b6 00             	movzbl (%rax),%eax
  8014c5:	84 c0                	test   %al,%al
  8014c7:	75 cc                	jne    801495 <strlcpy+0x25>
  8014c9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8014cd:	c6 00 00             	movb   $0x0,(%rax)
  8014d0:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8014d4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8014d8:	48 29 c2             	sub    %rax,%rdx
  8014db:	48 89 d0             	mov    %rdx,%rax
  8014de:	c9                   	leaveq 
  8014df:	c3                   	retq   

00000000008014e0 <strcmp>:
  8014e0:	55                   	push   %rbp
  8014e1:	48 89 e5             	mov    %rsp,%rbp
  8014e4:	48 83 ec 10          	sub    $0x10,%rsp
  8014e8:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8014ec:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8014f0:	eb 0a                	jmp    8014fc <strcmp+0x1c>
  8014f2:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8014f7:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  8014fc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801500:	0f b6 00             	movzbl (%rax),%eax
  801503:	84 c0                	test   %al,%al
  801505:	74 12                	je     801519 <strcmp+0x39>
  801507:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80150b:	0f b6 10             	movzbl (%rax),%edx
  80150e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801512:	0f b6 00             	movzbl (%rax),%eax
  801515:	38 c2                	cmp    %al,%dl
  801517:	74 d9                	je     8014f2 <strcmp+0x12>
  801519:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80151d:	0f b6 00             	movzbl (%rax),%eax
  801520:	0f b6 d0             	movzbl %al,%edx
  801523:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801527:	0f b6 00             	movzbl (%rax),%eax
  80152a:	0f b6 c0             	movzbl %al,%eax
  80152d:	29 c2                	sub    %eax,%edx
  80152f:	89 d0                	mov    %edx,%eax
  801531:	c9                   	leaveq 
  801532:	c3                   	retq   

0000000000801533 <strncmp>:
  801533:	55                   	push   %rbp
  801534:	48 89 e5             	mov    %rsp,%rbp
  801537:	48 83 ec 18          	sub    $0x18,%rsp
  80153b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80153f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801543:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801547:	eb 0f                	jmp    801558 <strncmp+0x25>
  801549:	48 83 6d e8 01       	subq   $0x1,-0x18(%rbp)
  80154e:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801553:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  801558:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80155d:	74 1d                	je     80157c <strncmp+0x49>
  80155f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801563:	0f b6 00             	movzbl (%rax),%eax
  801566:	84 c0                	test   %al,%al
  801568:	74 12                	je     80157c <strncmp+0x49>
  80156a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80156e:	0f b6 10             	movzbl (%rax),%edx
  801571:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801575:	0f b6 00             	movzbl (%rax),%eax
  801578:	38 c2                	cmp    %al,%dl
  80157a:	74 cd                	je     801549 <strncmp+0x16>
  80157c:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  801581:	75 07                	jne    80158a <strncmp+0x57>
  801583:	b8 00 00 00 00       	mov    $0x0,%eax
  801588:	eb 18                	jmp    8015a2 <strncmp+0x6f>
  80158a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80158e:	0f b6 00             	movzbl (%rax),%eax
  801591:	0f b6 d0             	movzbl %al,%edx
  801594:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801598:	0f b6 00             	movzbl (%rax),%eax
  80159b:	0f b6 c0             	movzbl %al,%eax
  80159e:	29 c2                	sub    %eax,%edx
  8015a0:	89 d0                	mov    %edx,%eax
  8015a2:	c9                   	leaveq 
  8015a3:	c3                   	retq   

00000000008015a4 <strchr>:
  8015a4:	55                   	push   %rbp
  8015a5:	48 89 e5             	mov    %rsp,%rbp
  8015a8:	48 83 ec 0c          	sub    $0xc,%rsp
  8015ac:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8015b0:	89 f0                	mov    %esi,%eax
  8015b2:	88 45 f4             	mov    %al,-0xc(%rbp)
  8015b5:	eb 17                	jmp    8015ce <strchr+0x2a>
  8015b7:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015bb:	0f b6 00             	movzbl (%rax),%eax
  8015be:	3a 45 f4             	cmp    -0xc(%rbp),%al
  8015c1:	75 06                	jne    8015c9 <strchr+0x25>
  8015c3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015c7:	eb 15                	jmp    8015de <strchr+0x3a>
  8015c9:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8015ce:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015d2:	0f b6 00             	movzbl (%rax),%eax
  8015d5:	84 c0                	test   %al,%al
  8015d7:	75 de                	jne    8015b7 <strchr+0x13>
  8015d9:	b8 00 00 00 00       	mov    $0x0,%eax
  8015de:	c9                   	leaveq 
  8015df:	c3                   	retq   

00000000008015e0 <strfind>:
  8015e0:	55                   	push   %rbp
  8015e1:	48 89 e5             	mov    %rsp,%rbp
  8015e4:	48 83 ec 0c          	sub    $0xc,%rsp
  8015e8:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8015ec:	89 f0                	mov    %esi,%eax
  8015ee:	88 45 f4             	mov    %al,-0xc(%rbp)
  8015f1:	eb 13                	jmp    801606 <strfind+0x26>
  8015f3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8015f7:	0f b6 00             	movzbl (%rax),%eax
  8015fa:	3a 45 f4             	cmp    -0xc(%rbp),%al
  8015fd:	75 02                	jne    801601 <strfind+0x21>
  8015ff:	eb 10                	jmp    801611 <strfind+0x31>
  801601:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801606:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80160a:	0f b6 00             	movzbl (%rax),%eax
  80160d:	84 c0                	test   %al,%al
  80160f:	75 e2                	jne    8015f3 <strfind+0x13>
  801611:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801615:	c9                   	leaveq 
  801616:	c3                   	retq   

0000000000801617 <memset>:
  801617:	55                   	push   %rbp
  801618:	48 89 e5             	mov    %rsp,%rbp
  80161b:	48 83 ec 18          	sub    $0x18,%rsp
  80161f:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801623:	89 75 f4             	mov    %esi,-0xc(%rbp)
  801626:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80162a:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80162f:	75 06                	jne    801637 <memset+0x20>
  801631:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801635:	eb 69                	jmp    8016a0 <memset+0x89>
  801637:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80163b:	83 e0 03             	and    $0x3,%eax
  80163e:	48 85 c0             	test   %rax,%rax
  801641:	75 48                	jne    80168b <memset+0x74>
  801643:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801647:	83 e0 03             	and    $0x3,%eax
  80164a:	48 85 c0             	test   %rax,%rax
  80164d:	75 3c                	jne    80168b <memset+0x74>
  80164f:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
  801656:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801659:	c1 e0 18             	shl    $0x18,%eax
  80165c:	89 c2                	mov    %eax,%edx
  80165e:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801661:	c1 e0 10             	shl    $0x10,%eax
  801664:	09 c2                	or     %eax,%edx
  801666:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801669:	c1 e0 08             	shl    $0x8,%eax
  80166c:	09 d0                	or     %edx,%eax
  80166e:	09 45 f4             	or     %eax,-0xc(%rbp)
  801671:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801675:	48 c1 e8 02          	shr    $0x2,%rax
  801679:	48 89 c1             	mov    %rax,%rcx
  80167c:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801680:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801683:	48 89 d7             	mov    %rdx,%rdi
  801686:	fc                   	cld    
  801687:	f3 ab                	rep stos %eax,%es:(%rdi)
  801689:	eb 11                	jmp    80169c <memset+0x85>
  80168b:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80168f:	8b 45 f4             	mov    -0xc(%rbp),%eax
  801692:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  801696:	48 89 d7             	mov    %rdx,%rdi
  801699:	fc                   	cld    
  80169a:	f3 aa                	rep stos %al,%es:(%rdi)
  80169c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016a0:	c9                   	leaveq 
  8016a1:	c3                   	retq   

00000000008016a2 <memmove>:
  8016a2:	55                   	push   %rbp
  8016a3:	48 89 e5             	mov    %rsp,%rbp
  8016a6:	48 83 ec 28          	sub    $0x28,%rsp
  8016aa:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8016ae:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8016b2:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8016b6:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8016ba:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8016be:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8016c2:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8016c6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016ca:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8016ce:	0f 83 88 00 00 00    	jae    80175c <memmove+0xba>
  8016d4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8016d8:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8016dc:	48 01 d0             	add    %rdx,%rax
  8016df:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  8016e3:	76 77                	jbe    80175c <memmove+0xba>
  8016e5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8016e9:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  8016ed:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8016f1:	48 01 45 f0          	add    %rax,-0x10(%rbp)
  8016f5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016f9:	83 e0 03             	and    $0x3,%eax
  8016fc:	48 85 c0             	test   %rax,%rax
  8016ff:	75 3b                	jne    80173c <memmove+0x9a>
  801701:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801705:	83 e0 03             	and    $0x3,%eax
  801708:	48 85 c0             	test   %rax,%rax
  80170b:	75 2f                	jne    80173c <memmove+0x9a>
  80170d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801711:	83 e0 03             	and    $0x3,%eax
  801714:	48 85 c0             	test   %rax,%rax
  801717:	75 23                	jne    80173c <memmove+0x9a>
  801719:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80171d:	48 83 e8 04          	sub    $0x4,%rax
  801721:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801725:	48 83 ea 04          	sub    $0x4,%rdx
  801729:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  80172d:	48 c1 e9 02          	shr    $0x2,%rcx
  801731:	48 89 c7             	mov    %rax,%rdi
  801734:	48 89 d6             	mov    %rdx,%rsi
  801737:	fd                   	std    
  801738:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  80173a:	eb 1d                	jmp    801759 <memmove+0xb7>
  80173c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801740:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  801744:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801748:	48 8d 70 ff          	lea    -0x1(%rax),%rsi
  80174c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801750:	48 89 d7             	mov    %rdx,%rdi
  801753:	48 89 c1             	mov    %rax,%rcx
  801756:	fd                   	std    
  801757:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  801759:	fc                   	cld    
  80175a:	eb 57                	jmp    8017b3 <memmove+0x111>
  80175c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801760:	83 e0 03             	and    $0x3,%eax
  801763:	48 85 c0             	test   %rax,%rax
  801766:	75 36                	jne    80179e <memmove+0xfc>
  801768:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80176c:	83 e0 03             	and    $0x3,%eax
  80176f:	48 85 c0             	test   %rax,%rax
  801772:	75 2a                	jne    80179e <memmove+0xfc>
  801774:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801778:	83 e0 03             	and    $0x3,%eax
  80177b:	48 85 c0             	test   %rax,%rax
  80177e:	75 1e                	jne    80179e <memmove+0xfc>
  801780:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801784:	48 c1 e8 02          	shr    $0x2,%rax
  801788:	48 89 c1             	mov    %rax,%rcx
  80178b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80178f:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801793:	48 89 c7             	mov    %rax,%rdi
  801796:	48 89 d6             	mov    %rdx,%rsi
  801799:	fc                   	cld    
  80179a:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  80179c:	eb 15                	jmp    8017b3 <memmove+0x111>
  80179e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8017a2:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8017a6:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  8017aa:	48 89 c7             	mov    %rax,%rdi
  8017ad:	48 89 d6             	mov    %rdx,%rsi
  8017b0:	fc                   	cld    
  8017b1:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  8017b3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8017b7:	c9                   	leaveq 
  8017b8:	c3                   	retq   

00000000008017b9 <memcpy>:
  8017b9:	55                   	push   %rbp
  8017ba:	48 89 e5             	mov    %rsp,%rbp
  8017bd:	48 83 ec 18          	sub    $0x18,%rsp
  8017c1:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8017c5:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8017c9:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8017cd:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8017d1:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  8017d5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017d9:	48 89 ce             	mov    %rcx,%rsi
  8017dc:	48 89 c7             	mov    %rax,%rdi
  8017df:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  8017e6:	00 00 00 
  8017e9:	ff d0                	callq  *%rax
  8017eb:	c9                   	leaveq 
  8017ec:	c3                   	retq   

00000000008017ed <memcmp>:
  8017ed:	55                   	push   %rbp
  8017ee:	48 89 e5             	mov    %rsp,%rbp
  8017f1:	48 83 ec 28          	sub    $0x28,%rsp
  8017f5:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8017f9:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8017fd:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801801:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801805:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801809:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80180d:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801811:	eb 36                	jmp    801849 <memcmp+0x5c>
  801813:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801817:	0f b6 10             	movzbl (%rax),%edx
  80181a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80181e:	0f b6 00             	movzbl (%rax),%eax
  801821:	38 c2                	cmp    %al,%dl
  801823:	74 1a                	je     80183f <memcmp+0x52>
  801825:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801829:	0f b6 00             	movzbl (%rax),%eax
  80182c:	0f b6 d0             	movzbl %al,%edx
  80182f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801833:	0f b6 00             	movzbl (%rax),%eax
  801836:	0f b6 c0             	movzbl %al,%eax
  801839:	29 c2                	sub    %eax,%edx
  80183b:	89 d0                	mov    %edx,%eax
  80183d:	eb 20                	jmp    80185f <memcmp+0x72>
  80183f:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801844:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  801849:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80184d:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  801851:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801855:	48 85 c0             	test   %rax,%rax
  801858:	75 b9                	jne    801813 <memcmp+0x26>
  80185a:	b8 00 00 00 00       	mov    $0x0,%eax
  80185f:	c9                   	leaveq 
  801860:	c3                   	retq   

0000000000801861 <memfind>:
  801861:	55                   	push   %rbp
  801862:	48 89 e5             	mov    %rsp,%rbp
  801865:	48 83 ec 28          	sub    $0x28,%rsp
  801869:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80186d:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  801870:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801874:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801878:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80187c:	48 01 d0             	add    %rdx,%rax
  80187f:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801883:	eb 15                	jmp    80189a <memfind+0x39>
  801885:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801889:	0f b6 10             	movzbl (%rax),%edx
  80188c:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80188f:	38 c2                	cmp    %al,%dl
  801891:	75 02                	jne    801895 <memfind+0x34>
  801893:	eb 0f                	jmp    8018a4 <memfind+0x43>
  801895:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  80189a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80189e:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  8018a2:	72 e1                	jb     801885 <memfind+0x24>
  8018a4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8018a8:	c9                   	leaveq 
  8018a9:	c3                   	retq   

00000000008018aa <strtol>:
  8018aa:	55                   	push   %rbp
  8018ab:	48 89 e5             	mov    %rsp,%rbp
  8018ae:	48 83 ec 34          	sub    $0x34,%rsp
  8018b2:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  8018b6:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8018ba:	89 55 cc             	mov    %edx,-0x34(%rbp)
  8018bd:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8018c4:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  8018cb:	00 
  8018cc:	eb 05                	jmp    8018d3 <strtol+0x29>
  8018ce:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8018d3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8018d7:	0f b6 00             	movzbl (%rax),%eax
  8018da:	3c 20                	cmp    $0x20,%al
  8018dc:	74 f0                	je     8018ce <strtol+0x24>
  8018de:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8018e2:	0f b6 00             	movzbl (%rax),%eax
  8018e5:	3c 09                	cmp    $0x9,%al
  8018e7:	74 e5                	je     8018ce <strtol+0x24>
  8018e9:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8018ed:	0f b6 00             	movzbl (%rax),%eax
  8018f0:	3c 2b                	cmp    $0x2b,%al
  8018f2:	75 07                	jne    8018fb <strtol+0x51>
  8018f4:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8018f9:	eb 17                	jmp    801912 <strtol+0x68>
  8018fb:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8018ff:	0f b6 00             	movzbl (%rax),%eax
  801902:	3c 2d                	cmp    $0x2d,%al
  801904:	75 0c                	jne    801912 <strtol+0x68>
  801906:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  80190b:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)
  801912:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801916:	74 06                	je     80191e <strtol+0x74>
  801918:	83 7d cc 10          	cmpl   $0x10,-0x34(%rbp)
  80191c:	75 28                	jne    801946 <strtol+0x9c>
  80191e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801922:	0f b6 00             	movzbl (%rax),%eax
  801925:	3c 30                	cmp    $0x30,%al
  801927:	75 1d                	jne    801946 <strtol+0x9c>
  801929:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80192d:	48 83 c0 01          	add    $0x1,%rax
  801931:	0f b6 00             	movzbl (%rax),%eax
  801934:	3c 78                	cmp    $0x78,%al
  801936:	75 0e                	jne    801946 <strtol+0x9c>
  801938:	48 83 45 d8 02       	addq   $0x2,-0x28(%rbp)
  80193d:	c7 45 cc 10 00 00 00 	movl   $0x10,-0x34(%rbp)
  801944:	eb 2c                	jmp    801972 <strtol+0xc8>
  801946:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  80194a:	75 19                	jne    801965 <strtol+0xbb>
  80194c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801950:	0f b6 00             	movzbl (%rax),%eax
  801953:	3c 30                	cmp    $0x30,%al
  801955:	75 0e                	jne    801965 <strtol+0xbb>
  801957:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  80195c:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%rbp)
  801963:	eb 0d                	jmp    801972 <strtol+0xc8>
  801965:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801969:	75 07                	jne    801972 <strtol+0xc8>
  80196b:	c7 45 cc 0a 00 00 00 	movl   $0xa,-0x34(%rbp)
  801972:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801976:	0f b6 00             	movzbl (%rax),%eax
  801979:	3c 2f                	cmp    $0x2f,%al
  80197b:	7e 1d                	jle    80199a <strtol+0xf0>
  80197d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801981:	0f b6 00             	movzbl (%rax),%eax
  801984:	3c 39                	cmp    $0x39,%al
  801986:	7f 12                	jg     80199a <strtol+0xf0>
  801988:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80198c:	0f b6 00             	movzbl (%rax),%eax
  80198f:	0f be c0             	movsbl %al,%eax
  801992:	83 e8 30             	sub    $0x30,%eax
  801995:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801998:	eb 4e                	jmp    8019e8 <strtol+0x13e>
  80199a:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80199e:	0f b6 00             	movzbl (%rax),%eax
  8019a1:	3c 60                	cmp    $0x60,%al
  8019a3:	7e 1d                	jle    8019c2 <strtol+0x118>
  8019a5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019a9:	0f b6 00             	movzbl (%rax),%eax
  8019ac:	3c 7a                	cmp    $0x7a,%al
  8019ae:	7f 12                	jg     8019c2 <strtol+0x118>
  8019b0:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019b4:	0f b6 00             	movzbl (%rax),%eax
  8019b7:	0f be c0             	movsbl %al,%eax
  8019ba:	83 e8 57             	sub    $0x57,%eax
  8019bd:	89 45 ec             	mov    %eax,-0x14(%rbp)
  8019c0:	eb 26                	jmp    8019e8 <strtol+0x13e>
  8019c2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019c6:	0f b6 00             	movzbl (%rax),%eax
  8019c9:	3c 40                	cmp    $0x40,%al
  8019cb:	7e 48                	jle    801a15 <strtol+0x16b>
  8019cd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019d1:	0f b6 00             	movzbl (%rax),%eax
  8019d4:	3c 5a                	cmp    $0x5a,%al
  8019d6:	7f 3d                	jg     801a15 <strtol+0x16b>
  8019d8:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019dc:	0f b6 00             	movzbl (%rax),%eax
  8019df:	0f be c0             	movsbl %al,%eax
  8019e2:	83 e8 37             	sub    $0x37,%eax
  8019e5:	89 45 ec             	mov    %eax,-0x14(%rbp)
  8019e8:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8019eb:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  8019ee:	7c 02                	jl     8019f2 <strtol+0x148>
  8019f0:	eb 23                	jmp    801a15 <strtol+0x16b>
  8019f2:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  8019f7:	8b 45 cc             	mov    -0x34(%rbp),%eax
  8019fa:	48 98                	cltq   
  8019fc:	48 0f af 45 f0       	imul   -0x10(%rbp),%rax
  801a01:	48 89 c2             	mov    %rax,%rdx
  801a04:	8b 45 ec             	mov    -0x14(%rbp),%eax
  801a07:	48 98                	cltq   
  801a09:	48 01 d0             	add    %rdx,%rax
  801a0c:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801a10:	e9 5d ff ff ff       	jmpq   801972 <strtol+0xc8>
  801a15:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  801a1a:	74 0b                	je     801a27 <strtol+0x17d>
  801a1c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801a20:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  801a24:	48 89 10             	mov    %rdx,(%rax)
  801a27:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  801a2b:	74 09                	je     801a36 <strtol+0x18c>
  801a2d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801a31:	48 f7 d8             	neg    %rax
  801a34:	eb 04                	jmp    801a3a <strtol+0x190>
  801a36:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801a3a:	c9                   	leaveq 
  801a3b:	c3                   	retq   

0000000000801a3c <strstr>:
  801a3c:	55                   	push   %rbp
  801a3d:	48 89 e5             	mov    %rsp,%rbp
  801a40:	48 83 ec 30          	sub    $0x30,%rsp
  801a44:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  801a48:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  801a4c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801a50:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801a54:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801a58:	0f b6 00             	movzbl (%rax),%eax
  801a5b:	88 45 ff             	mov    %al,-0x1(%rbp)
  801a5e:	80 7d ff 00          	cmpb   $0x0,-0x1(%rbp)
  801a62:	75 06                	jne    801a6a <strstr+0x2e>
  801a64:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a68:	eb 6b                	jmp    801ad5 <strstr+0x99>
  801a6a:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801a6e:	48 89 c7             	mov    %rax,%rdi
  801a71:	48 b8 12 13 80 00 00 	movabs $0x801312,%rax
  801a78:	00 00 00 
  801a7b:	ff d0                	callq  *%rax
  801a7d:	48 98                	cltq   
  801a7f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801a83:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801a87:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801a8b:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801a8f:	0f b6 00             	movzbl (%rax),%eax
  801a92:	88 45 ef             	mov    %al,-0x11(%rbp)
  801a95:	80 7d ef 00          	cmpb   $0x0,-0x11(%rbp)
  801a99:	75 07                	jne    801aa2 <strstr+0x66>
  801a9b:	b8 00 00 00 00       	mov    $0x0,%eax
  801aa0:	eb 33                	jmp    801ad5 <strstr+0x99>
  801aa2:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  801aa6:	3a 45 ff             	cmp    -0x1(%rbp),%al
  801aa9:	75 d8                	jne    801a83 <strstr+0x47>
  801aab:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801aaf:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  801ab3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801ab7:	48 89 ce             	mov    %rcx,%rsi
  801aba:	48 89 c7             	mov    %rax,%rdi
  801abd:	48 b8 33 15 80 00 00 	movabs $0x801533,%rax
  801ac4:	00 00 00 
  801ac7:	ff d0                	callq  *%rax
  801ac9:	85 c0                	test   %eax,%eax
  801acb:	75 b6                	jne    801a83 <strstr+0x47>
  801acd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801ad1:	48 83 e8 01          	sub    $0x1,%rax
  801ad5:	c9                   	leaveq 
  801ad6:	c3                   	retq   

0000000000801ad7 <syscall>:
  801ad7:	55                   	push   %rbp
  801ad8:	48 89 e5             	mov    %rsp,%rbp
  801adb:	53                   	push   %rbx
  801adc:	48 83 ec 48          	sub    $0x48,%rsp
  801ae0:	89 7d dc             	mov    %edi,-0x24(%rbp)
  801ae3:	89 75 d8             	mov    %esi,-0x28(%rbp)
  801ae6:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801aea:	48 89 4d c8          	mov    %rcx,-0x38(%rbp)
  801aee:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  801af2:	4c 89 4d b8          	mov    %r9,-0x48(%rbp)
  801af6:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801af9:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  801afd:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  801b01:	4c 8b 45 c0          	mov    -0x40(%rbp),%r8
  801b05:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  801b09:	48 8b 75 10          	mov    0x10(%rbp),%rsi
  801b0d:	4c 89 c3             	mov    %r8,%rbx
  801b10:	cd 30                	int    $0x30
  801b12:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801b16:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  801b1a:	74 3e                	je     801b5a <syscall+0x83>
  801b1c:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  801b21:	7e 37                	jle    801b5a <syscall+0x83>
  801b23:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801b27:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801b2a:	49 89 d0             	mov    %rdx,%r8
  801b2d:	89 c1                	mov    %eax,%ecx
  801b2f:	48 ba e8 4b 80 00 00 	movabs $0x804be8,%rdx
  801b36:	00 00 00 
  801b39:	be 24 00 00 00       	mov    $0x24,%esi
  801b3e:	48 bf 05 4c 80 00 00 	movabs $0x804c05,%rdi
  801b45:	00 00 00 
  801b48:	b8 00 00 00 00       	mov    $0x0,%eax
  801b4d:	49 b9 d5 41 80 00 00 	movabs $0x8041d5,%r9
  801b54:	00 00 00 
  801b57:	41 ff d1             	callq  *%r9
  801b5a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801b5e:	48 83 c4 48          	add    $0x48,%rsp
  801b62:	5b                   	pop    %rbx
  801b63:	5d                   	pop    %rbp
  801b64:	c3                   	retq   

0000000000801b65 <sys_cputs>:
  801b65:	55                   	push   %rbp
  801b66:	48 89 e5             	mov    %rsp,%rbp
  801b69:	48 83 ec 20          	sub    $0x20,%rsp
  801b6d:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801b71:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801b75:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801b79:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801b7d:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801b84:	00 
  801b85:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801b8b:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801b91:	48 89 d1             	mov    %rdx,%rcx
  801b94:	48 89 c2             	mov    %rax,%rdx
  801b97:	be 00 00 00 00       	mov    $0x0,%esi
  801b9c:	bf 00 00 00 00       	mov    $0x0,%edi
  801ba1:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801ba8:	00 00 00 
  801bab:	ff d0                	callq  *%rax
  801bad:	c9                   	leaveq 
  801bae:	c3                   	retq   

0000000000801baf <sys_cgetc>:
  801baf:	55                   	push   %rbp
  801bb0:	48 89 e5             	mov    %rsp,%rbp
  801bb3:	48 83 ec 10          	sub    $0x10,%rsp
  801bb7:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801bbe:	00 
  801bbf:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801bc5:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801bcb:	b9 00 00 00 00       	mov    $0x0,%ecx
  801bd0:	ba 00 00 00 00       	mov    $0x0,%edx
  801bd5:	be 00 00 00 00       	mov    $0x0,%esi
  801bda:	bf 01 00 00 00       	mov    $0x1,%edi
  801bdf:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801be6:	00 00 00 
  801be9:	ff d0                	callq  *%rax
  801beb:	c9                   	leaveq 
  801bec:	c3                   	retq   

0000000000801bed <sys_env_destroy>:
  801bed:	55                   	push   %rbp
  801bee:	48 89 e5             	mov    %rsp,%rbp
  801bf1:	48 83 ec 10          	sub    $0x10,%rsp
  801bf5:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801bf8:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801bfb:	48 98                	cltq   
  801bfd:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801c04:	00 
  801c05:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801c0b:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801c11:	b9 00 00 00 00       	mov    $0x0,%ecx
  801c16:	48 89 c2             	mov    %rax,%rdx
  801c19:	be 01 00 00 00       	mov    $0x1,%esi
  801c1e:	bf 03 00 00 00       	mov    $0x3,%edi
  801c23:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801c2a:	00 00 00 
  801c2d:	ff d0                	callq  *%rax
  801c2f:	c9                   	leaveq 
  801c30:	c3                   	retq   

0000000000801c31 <sys_getenvid>:
  801c31:	55                   	push   %rbp
  801c32:	48 89 e5             	mov    %rsp,%rbp
  801c35:	48 83 ec 10          	sub    $0x10,%rsp
  801c39:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801c40:	00 
  801c41:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801c47:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801c4d:	b9 00 00 00 00       	mov    $0x0,%ecx
  801c52:	ba 00 00 00 00       	mov    $0x0,%edx
  801c57:	be 00 00 00 00       	mov    $0x0,%esi
  801c5c:	bf 02 00 00 00       	mov    $0x2,%edi
  801c61:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801c68:	00 00 00 
  801c6b:	ff d0                	callq  *%rax
  801c6d:	c9                   	leaveq 
  801c6e:	c3                   	retq   

0000000000801c6f <sys_yield>:
  801c6f:	55                   	push   %rbp
  801c70:	48 89 e5             	mov    %rsp,%rbp
  801c73:	48 83 ec 10          	sub    $0x10,%rsp
  801c77:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801c7e:	00 
  801c7f:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801c85:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801c8b:	b9 00 00 00 00       	mov    $0x0,%ecx
  801c90:	ba 00 00 00 00       	mov    $0x0,%edx
  801c95:	be 00 00 00 00       	mov    $0x0,%esi
  801c9a:	bf 0b 00 00 00       	mov    $0xb,%edi
  801c9f:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801ca6:	00 00 00 
  801ca9:	ff d0                	callq  *%rax
  801cab:	c9                   	leaveq 
  801cac:	c3                   	retq   

0000000000801cad <sys_page_alloc>:
  801cad:	55                   	push   %rbp
  801cae:	48 89 e5             	mov    %rsp,%rbp
  801cb1:	48 83 ec 20          	sub    $0x20,%rsp
  801cb5:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801cb8:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801cbc:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801cbf:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801cc2:	48 63 c8             	movslq %eax,%rcx
  801cc5:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801cc9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801ccc:	48 98                	cltq   
  801cce:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801cd5:	00 
  801cd6:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801cdc:	49 89 c8             	mov    %rcx,%r8
  801cdf:	48 89 d1             	mov    %rdx,%rcx
  801ce2:	48 89 c2             	mov    %rax,%rdx
  801ce5:	be 01 00 00 00       	mov    $0x1,%esi
  801cea:	bf 04 00 00 00       	mov    $0x4,%edi
  801cef:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801cf6:	00 00 00 
  801cf9:	ff d0                	callq  *%rax
  801cfb:	c9                   	leaveq 
  801cfc:	c3                   	retq   

0000000000801cfd <sys_page_map>:
  801cfd:	55                   	push   %rbp
  801cfe:	48 89 e5             	mov    %rsp,%rbp
  801d01:	48 83 ec 30          	sub    $0x30,%rsp
  801d05:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801d08:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801d0c:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801d0f:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  801d13:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  801d17:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  801d1a:	48 63 c8             	movslq %eax,%rcx
  801d1d:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  801d21:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801d24:	48 63 f0             	movslq %eax,%rsi
  801d27:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801d2b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801d2e:	48 98                	cltq   
  801d30:	48 89 0c 24          	mov    %rcx,(%rsp)
  801d34:	49 89 f9             	mov    %rdi,%r9
  801d37:	49 89 f0             	mov    %rsi,%r8
  801d3a:	48 89 d1             	mov    %rdx,%rcx
  801d3d:	48 89 c2             	mov    %rax,%rdx
  801d40:	be 01 00 00 00       	mov    $0x1,%esi
  801d45:	bf 05 00 00 00       	mov    $0x5,%edi
  801d4a:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801d51:	00 00 00 
  801d54:	ff d0                	callq  *%rax
  801d56:	c9                   	leaveq 
  801d57:	c3                   	retq   

0000000000801d58 <sys_page_unmap>:
  801d58:	55                   	push   %rbp
  801d59:	48 89 e5             	mov    %rsp,%rbp
  801d5c:	48 83 ec 20          	sub    $0x20,%rsp
  801d60:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801d63:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801d67:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801d6b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801d6e:	48 98                	cltq   
  801d70:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801d77:	00 
  801d78:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801d7e:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801d84:	48 89 d1             	mov    %rdx,%rcx
  801d87:	48 89 c2             	mov    %rax,%rdx
  801d8a:	be 01 00 00 00       	mov    $0x1,%esi
  801d8f:	bf 06 00 00 00       	mov    $0x6,%edi
  801d94:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801d9b:	00 00 00 
  801d9e:	ff d0                	callq  *%rax
  801da0:	c9                   	leaveq 
  801da1:	c3                   	retq   

0000000000801da2 <sys_env_set_status>:
  801da2:	55                   	push   %rbp
  801da3:	48 89 e5             	mov    %rsp,%rbp
  801da6:	48 83 ec 10          	sub    $0x10,%rsp
  801daa:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801dad:	89 75 f8             	mov    %esi,-0x8(%rbp)
  801db0:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801db3:	48 63 d0             	movslq %eax,%rdx
  801db6:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801db9:	48 98                	cltq   
  801dbb:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801dc2:	00 
  801dc3:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801dc9:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801dcf:	48 89 d1             	mov    %rdx,%rcx
  801dd2:	48 89 c2             	mov    %rax,%rdx
  801dd5:	be 01 00 00 00       	mov    $0x1,%esi
  801dda:	bf 08 00 00 00       	mov    $0x8,%edi
  801ddf:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801de6:	00 00 00 
  801de9:	ff d0                	callq  *%rax
  801deb:	c9                   	leaveq 
  801dec:	c3                   	retq   

0000000000801ded <sys_env_set_trapframe>:
  801ded:	55                   	push   %rbp
  801dee:	48 89 e5             	mov    %rsp,%rbp
  801df1:	48 83 ec 20          	sub    $0x20,%rsp
  801df5:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801df8:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801dfc:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801e00:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801e03:	48 98                	cltq   
  801e05:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801e0c:	00 
  801e0d:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801e13:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801e19:	48 89 d1             	mov    %rdx,%rcx
  801e1c:	48 89 c2             	mov    %rax,%rdx
  801e1f:	be 01 00 00 00       	mov    $0x1,%esi
  801e24:	bf 09 00 00 00       	mov    $0x9,%edi
  801e29:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801e30:	00 00 00 
  801e33:	ff d0                	callq  *%rax
  801e35:	c9                   	leaveq 
  801e36:	c3                   	retq   

0000000000801e37 <sys_env_set_pgfault_upcall>:
  801e37:	55                   	push   %rbp
  801e38:	48 89 e5             	mov    %rsp,%rbp
  801e3b:	48 83 ec 20          	sub    $0x20,%rsp
  801e3f:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801e42:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801e46:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801e4a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801e4d:	48 98                	cltq   
  801e4f:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801e56:	00 
  801e57:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801e5d:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801e63:	48 89 d1             	mov    %rdx,%rcx
  801e66:	48 89 c2             	mov    %rax,%rdx
  801e69:	be 01 00 00 00       	mov    $0x1,%esi
  801e6e:	bf 0a 00 00 00       	mov    $0xa,%edi
  801e73:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801e7a:	00 00 00 
  801e7d:	ff d0                	callq  *%rax
  801e7f:	c9                   	leaveq 
  801e80:	c3                   	retq   

0000000000801e81 <sys_ipc_try_send>:
  801e81:	55                   	push   %rbp
  801e82:	48 89 e5             	mov    %rsp,%rbp
  801e85:	48 83 ec 20          	sub    $0x20,%rsp
  801e89:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801e8c:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801e90:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801e94:	89 4d f8             	mov    %ecx,-0x8(%rbp)
  801e97:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801e9a:	48 63 f0             	movslq %eax,%rsi
  801e9d:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  801ea1:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801ea4:	48 98                	cltq   
  801ea6:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801eaa:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801eb1:	00 
  801eb2:	49 89 f1             	mov    %rsi,%r9
  801eb5:	49 89 c8             	mov    %rcx,%r8
  801eb8:	48 89 d1             	mov    %rdx,%rcx
  801ebb:	48 89 c2             	mov    %rax,%rdx
  801ebe:	be 00 00 00 00       	mov    $0x0,%esi
  801ec3:	bf 0c 00 00 00       	mov    $0xc,%edi
  801ec8:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801ecf:	00 00 00 
  801ed2:	ff d0                	callq  *%rax
  801ed4:	c9                   	leaveq 
  801ed5:	c3                   	retq   

0000000000801ed6 <sys_ipc_recv>:
  801ed6:	55                   	push   %rbp
  801ed7:	48 89 e5             	mov    %rsp,%rbp
  801eda:	48 83 ec 10          	sub    $0x10,%rsp
  801ede:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801ee2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801ee6:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801eed:	00 
  801eee:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801ef4:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801efa:	b9 00 00 00 00       	mov    $0x0,%ecx
  801eff:	48 89 c2             	mov    %rax,%rdx
  801f02:	be 01 00 00 00       	mov    $0x1,%esi
  801f07:	bf 0d 00 00 00       	mov    $0xd,%edi
  801f0c:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801f13:	00 00 00 
  801f16:	ff d0                	callq  *%rax
  801f18:	c9                   	leaveq 
  801f19:	c3                   	retq   

0000000000801f1a <sys_time_msec>:
  801f1a:	55                   	push   %rbp
  801f1b:	48 89 e5             	mov    %rsp,%rbp
  801f1e:	48 83 ec 10          	sub    $0x10,%rsp
  801f22:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801f29:	00 
  801f2a:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801f30:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801f36:	b9 00 00 00 00       	mov    $0x0,%ecx
  801f3b:	ba 00 00 00 00       	mov    $0x0,%edx
  801f40:	be 00 00 00 00       	mov    $0x0,%esi
  801f45:	bf 0e 00 00 00       	mov    $0xe,%edi
  801f4a:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801f51:	00 00 00 
  801f54:	ff d0                	callq  *%rax
  801f56:	c9                   	leaveq 
  801f57:	c3                   	retq   

0000000000801f58 <sys_net_transmit>:
  801f58:	55                   	push   %rbp
  801f59:	48 89 e5             	mov    %rsp,%rbp
  801f5c:	48 83 ec 20          	sub    $0x20,%rsp
  801f60:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801f64:	89 75 f4             	mov    %esi,-0xc(%rbp)
  801f67:	8b 55 f4             	mov    -0xc(%rbp),%edx
  801f6a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801f6e:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801f75:	00 
  801f76:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801f7c:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801f82:	48 89 d1             	mov    %rdx,%rcx
  801f85:	48 89 c2             	mov    %rax,%rdx
  801f88:	be 00 00 00 00       	mov    $0x0,%esi
  801f8d:	bf 0f 00 00 00       	mov    $0xf,%edi
  801f92:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801f99:	00 00 00 
  801f9c:	ff d0                	callq  *%rax
  801f9e:	c9                   	leaveq 
  801f9f:	c3                   	retq   

0000000000801fa0 <sys_net_receive>:
  801fa0:	55                   	push   %rbp
  801fa1:	48 89 e5             	mov    %rsp,%rbp
  801fa4:	48 83 ec 20          	sub    $0x20,%rsp
  801fa8:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801fac:	89 75 f4             	mov    %esi,-0xc(%rbp)
  801faf:	8b 55 f4             	mov    -0xc(%rbp),%edx
  801fb2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801fb6:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801fbd:	00 
  801fbe:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801fc4:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801fca:	48 89 d1             	mov    %rdx,%rcx
  801fcd:	48 89 c2             	mov    %rax,%rdx
  801fd0:	be 00 00 00 00       	mov    $0x0,%esi
  801fd5:	bf 10 00 00 00       	mov    $0x10,%edi
  801fda:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  801fe1:	00 00 00 
  801fe4:	ff d0                	callq  *%rax
  801fe6:	c9                   	leaveq 
  801fe7:	c3                   	retq   

0000000000801fe8 <sys_ept_map>:
  801fe8:	55                   	push   %rbp
  801fe9:	48 89 e5             	mov    %rsp,%rbp
  801fec:	48 83 ec 30          	sub    $0x30,%rsp
  801ff0:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801ff3:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801ff7:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801ffa:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  801ffe:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  802002:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  802005:	48 63 c8             	movslq %eax,%rcx
  802008:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  80200c:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80200f:	48 63 f0             	movslq %eax,%rsi
  802012:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802016:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802019:	48 98                	cltq   
  80201b:	48 89 0c 24          	mov    %rcx,(%rsp)
  80201f:	49 89 f9             	mov    %rdi,%r9
  802022:	49 89 f0             	mov    %rsi,%r8
  802025:	48 89 d1             	mov    %rdx,%rcx
  802028:	48 89 c2             	mov    %rax,%rdx
  80202b:	be 00 00 00 00       	mov    $0x0,%esi
  802030:	bf 11 00 00 00       	mov    $0x11,%edi
  802035:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  80203c:	00 00 00 
  80203f:	ff d0                	callq  *%rax
  802041:	c9                   	leaveq 
  802042:	c3                   	retq   

0000000000802043 <sys_env_mkguest>:
  802043:	55                   	push   %rbp
  802044:	48 89 e5             	mov    %rsp,%rbp
  802047:	48 83 ec 20          	sub    $0x20,%rsp
  80204b:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80204f:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802053:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802057:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80205b:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802062:	00 
  802063:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802069:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  80206f:	48 89 d1             	mov    %rdx,%rcx
  802072:	48 89 c2             	mov    %rax,%rdx
  802075:	be 00 00 00 00       	mov    $0x0,%esi
  80207a:	bf 12 00 00 00       	mov    $0x12,%edi
  80207f:	48 b8 d7 1a 80 00 00 	movabs $0x801ad7,%rax
  802086:	00 00 00 
  802089:	ff d0                	callq  *%rax
  80208b:	c9                   	leaveq 
  80208c:	c3                   	retq   

000000000080208d <fd2num>:
  80208d:	55                   	push   %rbp
  80208e:	48 89 e5             	mov    %rsp,%rbp
  802091:	48 83 ec 08          	sub    $0x8,%rsp
  802095:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802099:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80209d:	48 b8 00 00 00 30 ff 	movabs $0xffffffff30000000,%rax
  8020a4:	ff ff ff 
  8020a7:	48 01 d0             	add    %rdx,%rax
  8020aa:	48 c1 e8 0c          	shr    $0xc,%rax
  8020ae:	c9                   	leaveq 
  8020af:	c3                   	retq   

00000000008020b0 <fd2data>:
  8020b0:	55                   	push   %rbp
  8020b1:	48 89 e5             	mov    %rsp,%rbp
  8020b4:	48 83 ec 08          	sub    $0x8,%rsp
  8020b8:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8020bc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8020c0:	48 89 c7             	mov    %rax,%rdi
  8020c3:	48 b8 8d 20 80 00 00 	movabs $0x80208d,%rax
  8020ca:	00 00 00 
  8020cd:	ff d0                	callq  *%rax
  8020cf:	48 05 20 00 0d 00    	add    $0xd0020,%rax
  8020d5:	48 c1 e0 0c          	shl    $0xc,%rax
  8020d9:	c9                   	leaveq 
  8020da:	c3                   	retq   

00000000008020db <fd_alloc>:
  8020db:	55                   	push   %rbp
  8020dc:	48 89 e5             	mov    %rsp,%rbp
  8020df:	48 83 ec 18          	sub    $0x18,%rsp
  8020e3:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8020e7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8020ee:	eb 6b                	jmp    80215b <fd_alloc+0x80>
  8020f0:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8020f3:	48 98                	cltq   
  8020f5:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  8020fb:	48 c1 e0 0c          	shl    $0xc,%rax
  8020ff:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  802103:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802107:	48 c1 e8 15          	shr    $0x15,%rax
  80210b:	48 89 c2             	mov    %rax,%rdx
  80210e:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  802115:	01 00 00 
  802118:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80211c:	83 e0 01             	and    $0x1,%eax
  80211f:	48 85 c0             	test   %rax,%rax
  802122:	74 21                	je     802145 <fd_alloc+0x6a>
  802124:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802128:	48 c1 e8 0c          	shr    $0xc,%rax
  80212c:	48 89 c2             	mov    %rax,%rdx
  80212f:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802136:	01 00 00 
  802139:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80213d:	83 e0 01             	and    $0x1,%eax
  802140:	48 85 c0             	test   %rax,%rax
  802143:	75 12                	jne    802157 <fd_alloc+0x7c>
  802145:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802149:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80214d:	48 89 10             	mov    %rdx,(%rax)
  802150:	b8 00 00 00 00       	mov    $0x0,%eax
  802155:	eb 1a                	jmp    802171 <fd_alloc+0x96>
  802157:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80215b:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  80215f:	7e 8f                	jle    8020f0 <fd_alloc+0x15>
  802161:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802165:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  80216c:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
  802171:	c9                   	leaveq 
  802172:	c3                   	retq   

0000000000802173 <fd_lookup>:
  802173:	55                   	push   %rbp
  802174:	48 89 e5             	mov    %rsp,%rbp
  802177:	48 83 ec 20          	sub    $0x20,%rsp
  80217b:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80217e:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802182:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  802186:	78 06                	js     80218e <fd_lookup+0x1b>
  802188:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%rbp)
  80218c:	7e 07                	jle    802195 <fd_lookup+0x22>
  80218e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802193:	eb 6c                	jmp    802201 <fd_lookup+0x8e>
  802195:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802198:	48 98                	cltq   
  80219a:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  8021a0:	48 c1 e0 0c          	shl    $0xc,%rax
  8021a4:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8021a8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8021ac:	48 c1 e8 15          	shr    $0x15,%rax
  8021b0:	48 89 c2             	mov    %rax,%rdx
  8021b3:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  8021ba:	01 00 00 
  8021bd:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8021c1:	83 e0 01             	and    $0x1,%eax
  8021c4:	48 85 c0             	test   %rax,%rax
  8021c7:	74 21                	je     8021ea <fd_lookup+0x77>
  8021c9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8021cd:	48 c1 e8 0c          	shr    $0xc,%rax
  8021d1:	48 89 c2             	mov    %rax,%rdx
  8021d4:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8021db:	01 00 00 
  8021de:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8021e2:	83 e0 01             	and    $0x1,%eax
  8021e5:	48 85 c0             	test   %rax,%rax
  8021e8:	75 07                	jne    8021f1 <fd_lookup+0x7e>
  8021ea:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8021ef:	eb 10                	jmp    802201 <fd_lookup+0x8e>
  8021f1:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8021f5:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8021f9:	48 89 10             	mov    %rdx,(%rax)
  8021fc:	b8 00 00 00 00       	mov    $0x0,%eax
  802201:	c9                   	leaveq 
  802202:	c3                   	retq   

0000000000802203 <fd_close>:
  802203:	55                   	push   %rbp
  802204:	48 89 e5             	mov    %rsp,%rbp
  802207:	48 83 ec 30          	sub    $0x30,%rsp
  80220b:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80220f:	89 f0                	mov    %esi,%eax
  802211:	88 45 d4             	mov    %al,-0x2c(%rbp)
  802214:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802218:	48 89 c7             	mov    %rax,%rdi
  80221b:	48 b8 8d 20 80 00 00 	movabs $0x80208d,%rax
  802222:	00 00 00 
  802225:	ff d0                	callq  *%rax
  802227:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80222b:	48 89 d6             	mov    %rdx,%rsi
  80222e:	89 c7                	mov    %eax,%edi
  802230:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  802237:	00 00 00 
  80223a:	ff d0                	callq  *%rax
  80223c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80223f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802243:	78 0a                	js     80224f <fd_close+0x4c>
  802245:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802249:	48 39 45 d8          	cmp    %rax,-0x28(%rbp)
  80224d:	74 12                	je     802261 <fd_close+0x5e>
  80224f:	80 7d d4 00          	cmpb   $0x0,-0x2c(%rbp)
  802253:	74 05                	je     80225a <fd_close+0x57>
  802255:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802258:	eb 05                	jmp    80225f <fd_close+0x5c>
  80225a:	b8 00 00 00 00       	mov    $0x0,%eax
  80225f:	eb 69                	jmp    8022ca <fd_close+0xc7>
  802261:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802265:	8b 00                	mov    (%rax),%eax
  802267:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  80226b:	48 89 d6             	mov    %rdx,%rsi
  80226e:	89 c7                	mov    %eax,%edi
  802270:	48 b8 cc 22 80 00 00 	movabs $0x8022cc,%rax
  802277:	00 00 00 
  80227a:	ff d0                	callq  *%rax
  80227c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80227f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802283:	78 2a                	js     8022af <fd_close+0xac>
  802285:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802289:	48 8b 40 20          	mov    0x20(%rax),%rax
  80228d:	48 85 c0             	test   %rax,%rax
  802290:	74 16                	je     8022a8 <fd_close+0xa5>
  802292:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802296:	48 8b 40 20          	mov    0x20(%rax),%rax
  80229a:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80229e:	48 89 d7             	mov    %rdx,%rdi
  8022a1:	ff d0                	callq  *%rax
  8022a3:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8022a6:	eb 07                	jmp    8022af <fd_close+0xac>
  8022a8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8022af:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8022b3:	48 89 c6             	mov    %rax,%rsi
  8022b6:	bf 00 00 00 00       	mov    $0x0,%edi
  8022bb:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  8022c2:	00 00 00 
  8022c5:	ff d0                	callq  *%rax
  8022c7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8022ca:	c9                   	leaveq 
  8022cb:	c3                   	retq   

00000000008022cc <dev_lookup>:
  8022cc:	55                   	push   %rbp
  8022cd:	48 89 e5             	mov    %rsp,%rbp
  8022d0:	48 83 ec 20          	sub    $0x20,%rsp
  8022d4:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8022d7:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8022db:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8022e2:	eb 41                	jmp    802325 <dev_lookup+0x59>
  8022e4:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  8022eb:	00 00 00 
  8022ee:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8022f1:	48 63 d2             	movslq %edx,%rdx
  8022f4:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8022f8:	8b 00                	mov    (%rax),%eax
  8022fa:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  8022fd:	75 22                	jne    802321 <dev_lookup+0x55>
  8022ff:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  802306:	00 00 00 
  802309:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80230c:	48 63 d2             	movslq %edx,%rdx
  80230f:	48 8b 14 d0          	mov    (%rax,%rdx,8),%rdx
  802313:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802317:	48 89 10             	mov    %rdx,(%rax)
  80231a:	b8 00 00 00 00       	mov    $0x0,%eax
  80231f:	eb 60                	jmp    802381 <dev_lookup+0xb5>
  802321:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  802325:	48 b8 20 60 80 00 00 	movabs $0x806020,%rax
  80232c:	00 00 00 
  80232f:	8b 55 fc             	mov    -0x4(%rbp),%edx
  802332:	48 63 d2             	movslq %edx,%rdx
  802335:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802339:	48 85 c0             	test   %rax,%rax
  80233c:	75 a6                	jne    8022e4 <dev_lookup+0x18>
  80233e:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  802345:	00 00 00 
  802348:	48 8b 00             	mov    (%rax),%rax
  80234b:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  802351:	8b 55 ec             	mov    -0x14(%rbp),%edx
  802354:	89 c6                	mov    %eax,%esi
  802356:	48 bf 18 4c 80 00 00 	movabs $0x804c18,%rdi
  80235d:	00 00 00 
  802360:	b8 00 00 00 00       	mov    $0x0,%eax
  802365:	48 b9 c9 07 80 00 00 	movabs $0x8007c9,%rcx
  80236c:	00 00 00 
  80236f:	ff d1                	callq  *%rcx
  802371:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802375:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  80237c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802381:	c9                   	leaveq 
  802382:	c3                   	retq   

0000000000802383 <close>:
  802383:	55                   	push   %rbp
  802384:	48 89 e5             	mov    %rsp,%rbp
  802387:	48 83 ec 20          	sub    $0x20,%rsp
  80238b:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80238e:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802392:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802395:	48 89 d6             	mov    %rdx,%rsi
  802398:	89 c7                	mov    %eax,%edi
  80239a:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  8023a1:	00 00 00 
  8023a4:	ff d0                	callq  *%rax
  8023a6:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8023a9:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8023ad:	79 05                	jns    8023b4 <close+0x31>
  8023af:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8023b2:	eb 18                	jmp    8023cc <close+0x49>
  8023b4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8023b8:	be 01 00 00 00       	mov    $0x1,%esi
  8023bd:	48 89 c7             	mov    %rax,%rdi
  8023c0:	48 b8 03 22 80 00 00 	movabs $0x802203,%rax
  8023c7:	00 00 00 
  8023ca:	ff d0                	callq  *%rax
  8023cc:	c9                   	leaveq 
  8023cd:	c3                   	retq   

00000000008023ce <close_all>:
  8023ce:	55                   	push   %rbp
  8023cf:	48 89 e5             	mov    %rsp,%rbp
  8023d2:	48 83 ec 10          	sub    $0x10,%rsp
  8023d6:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8023dd:	eb 15                	jmp    8023f4 <close_all+0x26>
  8023df:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8023e2:	89 c7                	mov    %eax,%edi
  8023e4:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  8023eb:	00 00 00 
  8023ee:	ff d0                	callq  *%rax
  8023f0:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8023f4:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  8023f8:	7e e5                	jle    8023df <close_all+0x11>
  8023fa:	c9                   	leaveq 
  8023fb:	c3                   	retq   

00000000008023fc <dup>:
  8023fc:	55                   	push   %rbp
  8023fd:	48 89 e5             	mov    %rsp,%rbp
  802400:	48 83 ec 40          	sub    $0x40,%rsp
  802404:	89 7d cc             	mov    %edi,-0x34(%rbp)
  802407:	89 75 c8             	mov    %esi,-0x38(%rbp)
  80240a:	48 8d 55 d8          	lea    -0x28(%rbp),%rdx
  80240e:	8b 45 cc             	mov    -0x34(%rbp),%eax
  802411:	48 89 d6             	mov    %rdx,%rsi
  802414:	89 c7                	mov    %eax,%edi
  802416:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  80241d:	00 00 00 
  802420:	ff d0                	callq  *%rax
  802422:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802425:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802429:	79 08                	jns    802433 <dup+0x37>
  80242b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80242e:	e9 70 01 00 00       	jmpq   8025a3 <dup+0x1a7>
  802433:	8b 45 c8             	mov    -0x38(%rbp),%eax
  802436:	89 c7                	mov    %eax,%edi
  802438:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  80243f:	00 00 00 
  802442:	ff d0                	callq  *%rax
  802444:	8b 45 c8             	mov    -0x38(%rbp),%eax
  802447:	48 98                	cltq   
  802449:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  80244f:	48 c1 e0 0c          	shl    $0xc,%rax
  802453:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  802457:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80245b:	48 89 c7             	mov    %rax,%rdi
  80245e:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  802465:	00 00 00 
  802468:	ff d0                	callq  *%rax
  80246a:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80246e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802472:	48 89 c7             	mov    %rax,%rdi
  802475:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  80247c:	00 00 00 
  80247f:	ff d0                	callq  *%rax
  802481:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  802485:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802489:	48 c1 e8 15          	shr    $0x15,%rax
  80248d:	48 89 c2             	mov    %rax,%rdx
  802490:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  802497:	01 00 00 
  80249a:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80249e:	83 e0 01             	and    $0x1,%eax
  8024a1:	48 85 c0             	test   %rax,%rax
  8024a4:	74 73                	je     802519 <dup+0x11d>
  8024a6:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8024aa:	48 c1 e8 0c          	shr    $0xc,%rax
  8024ae:	48 89 c2             	mov    %rax,%rdx
  8024b1:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8024b8:	01 00 00 
  8024bb:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8024bf:	83 e0 01             	and    $0x1,%eax
  8024c2:	48 85 c0             	test   %rax,%rax
  8024c5:	74 52                	je     802519 <dup+0x11d>
  8024c7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8024cb:	48 c1 e8 0c          	shr    $0xc,%rax
  8024cf:	48 89 c2             	mov    %rax,%rdx
  8024d2:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  8024d9:	01 00 00 
  8024dc:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8024e0:	25 07 0e 00 00       	and    $0xe07,%eax
  8024e5:	89 c1                	mov    %eax,%ecx
  8024e7:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8024eb:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8024ef:	41 89 c8             	mov    %ecx,%r8d
  8024f2:	48 89 d1             	mov    %rdx,%rcx
  8024f5:	ba 00 00 00 00       	mov    $0x0,%edx
  8024fa:	48 89 c6             	mov    %rax,%rsi
  8024fd:	bf 00 00 00 00       	mov    $0x0,%edi
  802502:	48 b8 fd 1c 80 00 00 	movabs $0x801cfd,%rax
  802509:	00 00 00 
  80250c:	ff d0                	callq  *%rax
  80250e:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802511:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802515:	79 02                	jns    802519 <dup+0x11d>
  802517:	eb 57                	jmp    802570 <dup+0x174>
  802519:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80251d:	48 c1 e8 0c          	shr    $0xc,%rax
  802521:	48 89 c2             	mov    %rax,%rdx
  802524:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  80252b:	01 00 00 
  80252e:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802532:	25 07 0e 00 00       	and    $0xe07,%eax
  802537:	89 c1                	mov    %eax,%ecx
  802539:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80253d:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802541:	41 89 c8             	mov    %ecx,%r8d
  802544:	48 89 d1             	mov    %rdx,%rcx
  802547:	ba 00 00 00 00       	mov    $0x0,%edx
  80254c:	48 89 c6             	mov    %rax,%rsi
  80254f:	bf 00 00 00 00       	mov    $0x0,%edi
  802554:	48 b8 fd 1c 80 00 00 	movabs $0x801cfd,%rax
  80255b:	00 00 00 
  80255e:	ff d0                	callq  *%rax
  802560:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802563:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802567:	79 02                	jns    80256b <dup+0x16f>
  802569:	eb 05                	jmp    802570 <dup+0x174>
  80256b:	8b 45 c8             	mov    -0x38(%rbp),%eax
  80256e:	eb 33                	jmp    8025a3 <dup+0x1a7>
  802570:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802574:	48 89 c6             	mov    %rax,%rsi
  802577:	bf 00 00 00 00       	mov    $0x0,%edi
  80257c:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  802583:	00 00 00 
  802586:	ff d0                	callq  *%rax
  802588:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80258c:	48 89 c6             	mov    %rax,%rsi
  80258f:	bf 00 00 00 00       	mov    $0x0,%edi
  802594:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  80259b:	00 00 00 
  80259e:	ff d0                	callq  *%rax
  8025a0:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8025a3:	c9                   	leaveq 
  8025a4:	c3                   	retq   

00000000008025a5 <read>:
  8025a5:	55                   	push   %rbp
  8025a6:	48 89 e5             	mov    %rsp,%rbp
  8025a9:	48 83 ec 40          	sub    $0x40,%rsp
  8025ad:	89 7d dc             	mov    %edi,-0x24(%rbp)
  8025b0:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8025b4:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  8025b8:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  8025bc:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8025bf:	48 89 d6             	mov    %rdx,%rsi
  8025c2:	89 c7                	mov    %eax,%edi
  8025c4:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  8025cb:	00 00 00 
  8025ce:	ff d0                	callq  *%rax
  8025d0:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8025d3:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8025d7:	78 24                	js     8025fd <read+0x58>
  8025d9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8025dd:	8b 00                	mov    (%rax),%eax
  8025df:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8025e3:	48 89 d6             	mov    %rdx,%rsi
  8025e6:	89 c7                	mov    %eax,%edi
  8025e8:	48 b8 cc 22 80 00 00 	movabs $0x8022cc,%rax
  8025ef:	00 00 00 
  8025f2:	ff d0                	callq  *%rax
  8025f4:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8025f7:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8025fb:	79 05                	jns    802602 <read+0x5d>
  8025fd:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802600:	eb 76                	jmp    802678 <read+0xd3>
  802602:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802606:	8b 40 08             	mov    0x8(%rax),%eax
  802609:	83 e0 03             	and    $0x3,%eax
  80260c:	83 f8 01             	cmp    $0x1,%eax
  80260f:	75 3a                	jne    80264b <read+0xa6>
  802611:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  802618:	00 00 00 
  80261b:	48 8b 00             	mov    (%rax),%rax
  80261e:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  802624:	8b 55 dc             	mov    -0x24(%rbp),%edx
  802627:	89 c6                	mov    %eax,%esi
  802629:	48 bf 37 4c 80 00 00 	movabs $0x804c37,%rdi
  802630:	00 00 00 
  802633:	b8 00 00 00 00       	mov    $0x0,%eax
  802638:	48 b9 c9 07 80 00 00 	movabs $0x8007c9,%rcx
  80263f:	00 00 00 
  802642:	ff d1                	callq  *%rcx
  802644:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802649:	eb 2d                	jmp    802678 <read+0xd3>
  80264b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80264f:	48 8b 40 10          	mov    0x10(%rax),%rax
  802653:	48 85 c0             	test   %rax,%rax
  802656:	75 07                	jne    80265f <read+0xba>
  802658:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  80265d:	eb 19                	jmp    802678 <read+0xd3>
  80265f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802663:	48 8b 40 10          	mov    0x10(%rax),%rax
  802667:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  80266b:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80266f:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  802673:	48 89 cf             	mov    %rcx,%rdi
  802676:	ff d0                	callq  *%rax
  802678:	c9                   	leaveq 
  802679:	c3                   	retq   

000000000080267a <readn>:
  80267a:	55                   	push   %rbp
  80267b:	48 89 e5             	mov    %rsp,%rbp
  80267e:	48 83 ec 30          	sub    $0x30,%rsp
  802682:	89 7d ec             	mov    %edi,-0x14(%rbp)
  802685:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802689:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80268d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802694:	eb 49                	jmp    8026df <readn+0x65>
  802696:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802699:	48 98                	cltq   
  80269b:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80269f:	48 29 c2             	sub    %rax,%rdx
  8026a2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8026a5:	48 63 c8             	movslq %eax,%rcx
  8026a8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8026ac:	48 01 c1             	add    %rax,%rcx
  8026af:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8026b2:	48 89 ce             	mov    %rcx,%rsi
  8026b5:	89 c7                	mov    %eax,%edi
  8026b7:	48 b8 a5 25 80 00 00 	movabs $0x8025a5,%rax
  8026be:	00 00 00 
  8026c1:	ff d0                	callq  *%rax
  8026c3:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8026c6:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8026ca:	79 05                	jns    8026d1 <readn+0x57>
  8026cc:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8026cf:	eb 1c                	jmp    8026ed <readn+0x73>
  8026d1:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8026d5:	75 02                	jne    8026d9 <readn+0x5f>
  8026d7:	eb 11                	jmp    8026ea <readn+0x70>
  8026d9:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8026dc:	01 45 fc             	add    %eax,-0x4(%rbp)
  8026df:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8026e2:	48 98                	cltq   
  8026e4:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8026e8:	72 ac                	jb     802696 <readn+0x1c>
  8026ea:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8026ed:	c9                   	leaveq 
  8026ee:	c3                   	retq   

00000000008026ef <write>:
  8026ef:	55                   	push   %rbp
  8026f0:	48 89 e5             	mov    %rsp,%rbp
  8026f3:	48 83 ec 40          	sub    $0x40,%rsp
  8026f7:	89 7d dc             	mov    %edi,-0x24(%rbp)
  8026fa:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8026fe:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802702:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802706:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802709:	48 89 d6             	mov    %rdx,%rsi
  80270c:	89 c7                	mov    %eax,%edi
  80270e:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  802715:	00 00 00 
  802718:	ff d0                	callq  *%rax
  80271a:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80271d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802721:	78 24                	js     802747 <write+0x58>
  802723:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802727:	8b 00                	mov    (%rax),%eax
  802729:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80272d:	48 89 d6             	mov    %rdx,%rsi
  802730:	89 c7                	mov    %eax,%edi
  802732:	48 b8 cc 22 80 00 00 	movabs $0x8022cc,%rax
  802739:	00 00 00 
  80273c:	ff d0                	callq  *%rax
  80273e:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802741:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802745:	79 05                	jns    80274c <write+0x5d>
  802747:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80274a:	eb 75                	jmp    8027c1 <write+0xd2>
  80274c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802750:	8b 40 08             	mov    0x8(%rax),%eax
  802753:	83 e0 03             	and    $0x3,%eax
  802756:	85 c0                	test   %eax,%eax
  802758:	75 3a                	jne    802794 <write+0xa5>
  80275a:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  802761:	00 00 00 
  802764:	48 8b 00             	mov    (%rax),%rax
  802767:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80276d:	8b 55 dc             	mov    -0x24(%rbp),%edx
  802770:	89 c6                	mov    %eax,%esi
  802772:	48 bf 53 4c 80 00 00 	movabs $0x804c53,%rdi
  802779:	00 00 00 
  80277c:	b8 00 00 00 00       	mov    $0x0,%eax
  802781:	48 b9 c9 07 80 00 00 	movabs $0x8007c9,%rcx
  802788:	00 00 00 
  80278b:	ff d1                	callq  *%rcx
  80278d:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802792:	eb 2d                	jmp    8027c1 <write+0xd2>
  802794:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802798:	48 8b 40 18          	mov    0x18(%rax),%rax
  80279c:	48 85 c0             	test   %rax,%rax
  80279f:	75 07                	jne    8027a8 <write+0xb9>
  8027a1:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  8027a6:	eb 19                	jmp    8027c1 <write+0xd2>
  8027a8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8027ac:	48 8b 40 18          	mov    0x18(%rax),%rax
  8027b0:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8027b4:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8027b8:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8027bc:	48 89 cf             	mov    %rcx,%rdi
  8027bf:	ff d0                	callq  *%rax
  8027c1:	c9                   	leaveq 
  8027c2:	c3                   	retq   

00000000008027c3 <seek>:
  8027c3:	55                   	push   %rbp
  8027c4:	48 89 e5             	mov    %rsp,%rbp
  8027c7:	48 83 ec 18          	sub    $0x18,%rsp
  8027cb:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8027ce:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8027d1:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8027d5:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8027d8:	48 89 d6             	mov    %rdx,%rsi
  8027db:	89 c7                	mov    %eax,%edi
  8027dd:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  8027e4:	00 00 00 
  8027e7:	ff d0                	callq  *%rax
  8027e9:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8027ec:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8027f0:	79 05                	jns    8027f7 <seek+0x34>
  8027f2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8027f5:	eb 0f                	jmp    802806 <seek+0x43>
  8027f7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8027fb:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8027fe:	89 50 04             	mov    %edx,0x4(%rax)
  802801:	b8 00 00 00 00       	mov    $0x0,%eax
  802806:	c9                   	leaveq 
  802807:	c3                   	retq   

0000000000802808 <ftruncate>:
  802808:	55                   	push   %rbp
  802809:	48 89 e5             	mov    %rsp,%rbp
  80280c:	48 83 ec 30          	sub    $0x30,%rsp
  802810:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802813:	89 75 d8             	mov    %esi,-0x28(%rbp)
  802816:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  80281a:	8b 45 dc             	mov    -0x24(%rbp),%eax
  80281d:	48 89 d6             	mov    %rdx,%rsi
  802820:	89 c7                	mov    %eax,%edi
  802822:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  802829:	00 00 00 
  80282c:	ff d0                	callq  *%rax
  80282e:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802831:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802835:	78 24                	js     80285b <ftruncate+0x53>
  802837:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80283b:	8b 00                	mov    (%rax),%eax
  80283d:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802841:	48 89 d6             	mov    %rdx,%rsi
  802844:	89 c7                	mov    %eax,%edi
  802846:	48 b8 cc 22 80 00 00 	movabs $0x8022cc,%rax
  80284d:	00 00 00 
  802850:	ff d0                	callq  *%rax
  802852:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802855:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802859:	79 05                	jns    802860 <ftruncate+0x58>
  80285b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80285e:	eb 72                	jmp    8028d2 <ftruncate+0xca>
  802860:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802864:	8b 40 08             	mov    0x8(%rax),%eax
  802867:	83 e0 03             	and    $0x3,%eax
  80286a:	85 c0                	test   %eax,%eax
  80286c:	75 3a                	jne    8028a8 <ftruncate+0xa0>
  80286e:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  802875:	00 00 00 
  802878:	48 8b 00             	mov    (%rax),%rax
  80287b:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  802881:	8b 55 dc             	mov    -0x24(%rbp),%edx
  802884:	89 c6                	mov    %eax,%esi
  802886:	48 bf 70 4c 80 00 00 	movabs $0x804c70,%rdi
  80288d:	00 00 00 
  802890:	b8 00 00 00 00       	mov    $0x0,%eax
  802895:	48 b9 c9 07 80 00 00 	movabs $0x8007c9,%rcx
  80289c:	00 00 00 
  80289f:	ff d1                	callq  *%rcx
  8028a1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8028a6:	eb 2a                	jmp    8028d2 <ftruncate+0xca>
  8028a8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8028ac:	48 8b 40 30          	mov    0x30(%rax),%rax
  8028b0:	48 85 c0             	test   %rax,%rax
  8028b3:	75 07                	jne    8028bc <ftruncate+0xb4>
  8028b5:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  8028ba:	eb 16                	jmp    8028d2 <ftruncate+0xca>
  8028bc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8028c0:	48 8b 40 30          	mov    0x30(%rax),%rax
  8028c4:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  8028c8:	8b 4d d8             	mov    -0x28(%rbp),%ecx
  8028cb:	89 ce                	mov    %ecx,%esi
  8028cd:	48 89 d7             	mov    %rdx,%rdi
  8028d0:	ff d0                	callq  *%rax
  8028d2:	c9                   	leaveq 
  8028d3:	c3                   	retq   

00000000008028d4 <fstat>:
  8028d4:	55                   	push   %rbp
  8028d5:	48 89 e5             	mov    %rsp,%rbp
  8028d8:	48 83 ec 30          	sub    $0x30,%rsp
  8028dc:	89 7d dc             	mov    %edi,-0x24(%rbp)
  8028df:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  8028e3:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  8028e7:	8b 45 dc             	mov    -0x24(%rbp),%eax
  8028ea:	48 89 d6             	mov    %rdx,%rsi
  8028ed:	89 c7                	mov    %eax,%edi
  8028ef:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  8028f6:	00 00 00 
  8028f9:	ff d0                	callq  *%rax
  8028fb:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8028fe:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802902:	78 24                	js     802928 <fstat+0x54>
  802904:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802908:	8b 00                	mov    (%rax),%eax
  80290a:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80290e:	48 89 d6             	mov    %rdx,%rsi
  802911:	89 c7                	mov    %eax,%edi
  802913:	48 b8 cc 22 80 00 00 	movabs $0x8022cc,%rax
  80291a:	00 00 00 
  80291d:	ff d0                	callq  *%rax
  80291f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802922:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802926:	79 05                	jns    80292d <fstat+0x59>
  802928:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80292b:	eb 5e                	jmp    80298b <fstat+0xb7>
  80292d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802931:	48 8b 40 28          	mov    0x28(%rax),%rax
  802935:	48 85 c0             	test   %rax,%rax
  802938:	75 07                	jne    802941 <fstat+0x6d>
  80293a:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  80293f:	eb 4a                	jmp    80298b <fstat+0xb7>
  802941:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802945:	c6 00 00             	movb   $0x0,(%rax)
  802948:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80294c:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%rax)
  802953:	00 00 00 
  802956:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80295a:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  802961:	00 00 00 
  802964:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802968:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80296c:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
  802973:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802977:	48 8b 40 28          	mov    0x28(%rax),%rax
  80297b:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80297f:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  802983:	48 89 ce             	mov    %rcx,%rsi
  802986:	48 89 d7             	mov    %rdx,%rdi
  802989:	ff d0                	callq  *%rax
  80298b:	c9                   	leaveq 
  80298c:	c3                   	retq   

000000000080298d <stat>:
  80298d:	55                   	push   %rbp
  80298e:	48 89 e5             	mov    %rsp,%rbp
  802991:	48 83 ec 20          	sub    $0x20,%rsp
  802995:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802999:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80299d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8029a1:	be 00 00 00 00       	mov    $0x0,%esi
  8029a6:	48 89 c7             	mov    %rax,%rdi
  8029a9:	48 b8 7b 2a 80 00 00 	movabs $0x802a7b,%rax
  8029b0:	00 00 00 
  8029b3:	ff d0                	callq  *%rax
  8029b5:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8029b8:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8029bc:	79 05                	jns    8029c3 <stat+0x36>
  8029be:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8029c1:	eb 2f                	jmp    8029f2 <stat+0x65>
  8029c3:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8029c7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8029ca:	48 89 d6             	mov    %rdx,%rsi
  8029cd:	89 c7                	mov    %eax,%edi
  8029cf:	48 b8 d4 28 80 00 00 	movabs $0x8028d4,%rax
  8029d6:	00 00 00 
  8029d9:	ff d0                	callq  *%rax
  8029db:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8029de:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8029e1:	89 c7                	mov    %eax,%edi
  8029e3:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  8029ea:	00 00 00 
  8029ed:	ff d0                	callq  *%rax
  8029ef:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8029f2:	c9                   	leaveq 
  8029f3:	c3                   	retq   

00000000008029f4 <fsipc>:
  8029f4:	55                   	push   %rbp
  8029f5:	48 89 e5             	mov    %rsp,%rbp
  8029f8:	48 83 ec 10          	sub    $0x10,%rsp
  8029fc:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8029ff:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802a03:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  802a0a:	00 00 00 
  802a0d:	8b 00                	mov    (%rax),%eax
  802a0f:	85 c0                	test   %eax,%eax
  802a11:	75 1d                	jne    802a30 <fsipc+0x3c>
  802a13:	bf 01 00 00 00       	mov    $0x1,%edi
  802a18:	48 b8 b5 44 80 00 00 	movabs $0x8044b5,%rax
  802a1f:	00 00 00 
  802a22:	ff d0                	callq  *%rax
  802a24:	48 ba 00 70 80 00 00 	movabs $0x807000,%rdx
  802a2b:	00 00 00 
  802a2e:	89 02                	mov    %eax,(%rdx)
  802a30:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  802a37:	00 00 00 
  802a3a:	8b 00                	mov    (%rax),%eax
  802a3c:	8b 75 fc             	mov    -0x4(%rbp),%esi
  802a3f:	b9 07 00 00 00       	mov    $0x7,%ecx
  802a44:	48 ba 00 80 80 00 00 	movabs $0x808000,%rdx
  802a4b:	00 00 00 
  802a4e:	89 c7                	mov    %eax,%edi
  802a50:	48 b8 aa 43 80 00 00 	movabs $0x8043aa,%rax
  802a57:	00 00 00 
  802a5a:	ff d0                	callq  *%rax
  802a5c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802a60:	ba 00 00 00 00       	mov    $0x0,%edx
  802a65:	48 89 c6             	mov    %rax,%rsi
  802a68:	bf 00 00 00 00       	mov    $0x0,%edi
  802a6d:	48 b8 e9 42 80 00 00 	movabs $0x8042e9,%rax
  802a74:	00 00 00 
  802a77:	ff d0                	callq  *%rax
  802a79:	c9                   	leaveq 
  802a7a:	c3                   	retq   

0000000000802a7b <open>:
  802a7b:	55                   	push   %rbp
  802a7c:	48 89 e5             	mov    %rsp,%rbp
  802a7f:	48 83 ec 20          	sub    $0x20,%rsp
  802a83:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802a87:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  802a8a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802a8e:	48 89 c7             	mov    %rax,%rdi
  802a91:	48 b8 12 13 80 00 00 	movabs $0x801312,%rax
  802a98:	00 00 00 
  802a9b:	ff d0                	callq  *%rax
  802a9d:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  802aa2:	7e 0a                	jle    802aae <open+0x33>
  802aa4:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  802aa9:	e9 a5 00 00 00       	jmpq   802b53 <open+0xd8>
  802aae:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  802ab2:	48 89 c7             	mov    %rax,%rdi
  802ab5:	48 b8 db 20 80 00 00 	movabs $0x8020db,%rax
  802abc:	00 00 00 
  802abf:	ff d0                	callq  *%rax
  802ac1:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802ac4:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802ac8:	79 08                	jns    802ad2 <open+0x57>
  802aca:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802acd:	e9 81 00 00 00       	jmpq   802b53 <open+0xd8>
  802ad2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802ad6:	48 89 c6             	mov    %rax,%rsi
  802ad9:	48 bf 00 80 80 00 00 	movabs $0x808000,%rdi
  802ae0:	00 00 00 
  802ae3:	48 b8 7e 13 80 00 00 	movabs $0x80137e,%rax
  802aea:	00 00 00 
  802aed:	ff d0                	callq  *%rax
  802aef:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802af6:	00 00 00 
  802af9:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  802afc:	89 90 00 04 00 00    	mov    %edx,0x400(%rax)
  802b02:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802b06:	48 89 c6             	mov    %rax,%rsi
  802b09:	bf 01 00 00 00       	mov    $0x1,%edi
  802b0e:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802b15:	00 00 00 
  802b18:	ff d0                	callq  *%rax
  802b1a:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802b1d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802b21:	79 1d                	jns    802b40 <open+0xc5>
  802b23:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802b27:	be 00 00 00 00       	mov    $0x0,%esi
  802b2c:	48 89 c7             	mov    %rax,%rdi
  802b2f:	48 b8 03 22 80 00 00 	movabs $0x802203,%rax
  802b36:	00 00 00 
  802b39:	ff d0                	callq  *%rax
  802b3b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802b3e:	eb 13                	jmp    802b53 <open+0xd8>
  802b40:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802b44:	48 89 c7             	mov    %rax,%rdi
  802b47:	48 b8 8d 20 80 00 00 	movabs $0x80208d,%rax
  802b4e:	00 00 00 
  802b51:	ff d0                	callq  *%rax
  802b53:	c9                   	leaveq 
  802b54:	c3                   	retq   

0000000000802b55 <devfile_flush>:
  802b55:	55                   	push   %rbp
  802b56:	48 89 e5             	mov    %rsp,%rbp
  802b59:	48 83 ec 10          	sub    $0x10,%rsp
  802b5d:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802b61:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802b65:	8b 50 0c             	mov    0xc(%rax),%edx
  802b68:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802b6f:	00 00 00 
  802b72:	89 10                	mov    %edx,(%rax)
  802b74:	be 00 00 00 00       	mov    $0x0,%esi
  802b79:	bf 06 00 00 00       	mov    $0x6,%edi
  802b7e:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802b85:	00 00 00 
  802b88:	ff d0                	callq  *%rax
  802b8a:	c9                   	leaveq 
  802b8b:	c3                   	retq   

0000000000802b8c <devfile_read>:
  802b8c:	55                   	push   %rbp
  802b8d:	48 89 e5             	mov    %rsp,%rbp
  802b90:	48 83 ec 30          	sub    $0x30,%rsp
  802b94:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802b98:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802b9c:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  802ba0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802ba4:	8b 50 0c             	mov    0xc(%rax),%edx
  802ba7:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802bae:	00 00 00 
  802bb1:	89 10                	mov    %edx,(%rax)
  802bb3:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802bba:	00 00 00 
  802bbd:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  802bc1:	48 89 50 08          	mov    %rdx,0x8(%rax)
  802bc5:	be 00 00 00 00       	mov    $0x0,%esi
  802bca:	bf 03 00 00 00       	mov    $0x3,%edi
  802bcf:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802bd6:	00 00 00 
  802bd9:	ff d0                	callq  *%rax
  802bdb:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802bde:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802be2:	79 08                	jns    802bec <devfile_read+0x60>
  802be4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802be7:	e9 a4 00 00 00       	jmpq   802c90 <devfile_read+0x104>
  802bec:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802bef:	48 98                	cltq   
  802bf1:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  802bf5:	76 35                	jbe    802c2c <devfile_read+0xa0>
  802bf7:	48 b9 96 4c 80 00 00 	movabs $0x804c96,%rcx
  802bfe:	00 00 00 
  802c01:	48 ba 9d 4c 80 00 00 	movabs $0x804c9d,%rdx
  802c08:	00 00 00 
  802c0b:	be 89 00 00 00       	mov    $0x89,%esi
  802c10:	48 bf b2 4c 80 00 00 	movabs $0x804cb2,%rdi
  802c17:	00 00 00 
  802c1a:	b8 00 00 00 00       	mov    $0x0,%eax
  802c1f:	49 b8 d5 41 80 00 00 	movabs $0x8041d5,%r8
  802c26:	00 00 00 
  802c29:	41 ff d0             	callq  *%r8
  802c2c:	81 7d fc 00 10 00 00 	cmpl   $0x1000,-0x4(%rbp)
  802c33:	7e 35                	jle    802c6a <devfile_read+0xde>
  802c35:	48 b9 c0 4c 80 00 00 	movabs $0x804cc0,%rcx
  802c3c:	00 00 00 
  802c3f:	48 ba 9d 4c 80 00 00 	movabs $0x804c9d,%rdx
  802c46:	00 00 00 
  802c49:	be 8a 00 00 00       	mov    $0x8a,%esi
  802c4e:	48 bf b2 4c 80 00 00 	movabs $0x804cb2,%rdi
  802c55:	00 00 00 
  802c58:	b8 00 00 00 00       	mov    $0x0,%eax
  802c5d:	49 b8 d5 41 80 00 00 	movabs $0x8041d5,%r8
  802c64:	00 00 00 
  802c67:	41 ff d0             	callq  *%r8
  802c6a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802c6d:	48 63 d0             	movslq %eax,%rdx
  802c70:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802c74:	48 be 00 80 80 00 00 	movabs $0x808000,%rsi
  802c7b:	00 00 00 
  802c7e:	48 89 c7             	mov    %rax,%rdi
  802c81:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  802c88:	00 00 00 
  802c8b:	ff d0                	callq  *%rax
  802c8d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802c90:	c9                   	leaveq 
  802c91:	c3                   	retq   

0000000000802c92 <devfile_write>:
  802c92:	55                   	push   %rbp
  802c93:	48 89 e5             	mov    %rsp,%rbp
  802c96:	48 83 ec 40          	sub    $0x40,%rsp
  802c9a:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  802c9e:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802ca2:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802ca6:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  802caa:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  802cae:	48 c7 45 f0 f4 0f 00 	movq   $0xff4,-0x10(%rbp)
  802cb5:	00 
  802cb6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802cba:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  802cbe:	48 0f 46 45 f8       	cmovbe -0x8(%rbp),%rax
  802cc3:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
  802cc7:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802ccb:	8b 50 0c             	mov    0xc(%rax),%edx
  802cce:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802cd5:	00 00 00 
  802cd8:	89 10                	mov    %edx,(%rax)
  802cda:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802ce1:	00 00 00 
  802ce4:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802ce8:	48 89 50 08          	mov    %rdx,0x8(%rax)
  802cec:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802cf0:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802cf4:	48 89 c6             	mov    %rax,%rsi
  802cf7:	48 bf 10 80 80 00 00 	movabs $0x808010,%rdi
  802cfe:	00 00 00 
  802d01:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  802d08:	00 00 00 
  802d0b:	ff d0                	callq  *%rax
  802d0d:	be 00 00 00 00       	mov    $0x0,%esi
  802d12:	bf 04 00 00 00       	mov    $0x4,%edi
  802d17:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802d1e:	00 00 00 
  802d21:	ff d0                	callq  *%rax
  802d23:	89 45 ec             	mov    %eax,-0x14(%rbp)
  802d26:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  802d2a:	79 05                	jns    802d31 <devfile_write+0x9f>
  802d2c:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802d2f:	eb 43                	jmp    802d74 <devfile_write+0xe2>
  802d31:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802d34:	48 98                	cltq   
  802d36:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  802d3a:	76 35                	jbe    802d71 <devfile_write+0xdf>
  802d3c:	48 b9 96 4c 80 00 00 	movabs $0x804c96,%rcx
  802d43:	00 00 00 
  802d46:	48 ba 9d 4c 80 00 00 	movabs $0x804c9d,%rdx
  802d4d:	00 00 00 
  802d50:	be a8 00 00 00       	mov    $0xa8,%esi
  802d55:	48 bf b2 4c 80 00 00 	movabs $0x804cb2,%rdi
  802d5c:	00 00 00 
  802d5f:	b8 00 00 00 00       	mov    $0x0,%eax
  802d64:	49 b8 d5 41 80 00 00 	movabs $0x8041d5,%r8
  802d6b:	00 00 00 
  802d6e:	41 ff d0             	callq  *%r8
  802d71:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802d74:	c9                   	leaveq 
  802d75:	c3                   	retq   

0000000000802d76 <devfile_stat>:
  802d76:	55                   	push   %rbp
  802d77:	48 89 e5             	mov    %rsp,%rbp
  802d7a:	48 83 ec 20          	sub    $0x20,%rsp
  802d7e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802d82:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802d86:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802d8a:	8b 50 0c             	mov    0xc(%rax),%edx
  802d8d:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d94:	00 00 00 
  802d97:	89 10                	mov    %edx,(%rax)
  802d99:	be 00 00 00 00       	mov    $0x0,%esi
  802d9e:	bf 05 00 00 00       	mov    $0x5,%edi
  802da3:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802daa:	00 00 00 
  802dad:	ff d0                	callq  *%rax
  802daf:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802db2:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802db6:	79 05                	jns    802dbd <devfile_stat+0x47>
  802db8:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802dbb:	eb 56                	jmp    802e13 <devfile_stat+0x9d>
  802dbd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802dc1:	48 be 00 80 80 00 00 	movabs $0x808000,%rsi
  802dc8:	00 00 00 
  802dcb:	48 89 c7             	mov    %rax,%rdi
  802dce:	48 b8 7e 13 80 00 00 	movabs $0x80137e,%rax
  802dd5:	00 00 00 
  802dd8:	ff d0                	callq  *%rax
  802dda:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802de1:	00 00 00 
  802de4:	8b 90 80 00 00 00    	mov    0x80(%rax),%edx
  802dea:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802dee:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  802df4:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802dfb:	00 00 00 
  802dfe:	8b 90 84 00 00 00    	mov    0x84(%rax),%edx
  802e04:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802e08:	89 90 84 00 00 00    	mov    %edx,0x84(%rax)
  802e0e:	b8 00 00 00 00       	mov    $0x0,%eax
  802e13:	c9                   	leaveq 
  802e14:	c3                   	retq   

0000000000802e15 <devfile_trunc>:
  802e15:	55                   	push   %rbp
  802e16:	48 89 e5             	mov    %rsp,%rbp
  802e19:	48 83 ec 10          	sub    $0x10,%rsp
  802e1d:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802e21:	89 75 f4             	mov    %esi,-0xc(%rbp)
  802e24:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802e28:	8b 50 0c             	mov    0xc(%rax),%edx
  802e2b:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802e32:	00 00 00 
  802e35:	89 10                	mov    %edx,(%rax)
  802e37:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802e3e:	00 00 00 
  802e41:	8b 55 f4             	mov    -0xc(%rbp),%edx
  802e44:	89 50 04             	mov    %edx,0x4(%rax)
  802e47:	be 00 00 00 00       	mov    $0x0,%esi
  802e4c:	bf 02 00 00 00       	mov    $0x2,%edi
  802e51:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802e58:	00 00 00 
  802e5b:	ff d0                	callq  *%rax
  802e5d:	c9                   	leaveq 
  802e5e:	c3                   	retq   

0000000000802e5f <remove>:
  802e5f:	55                   	push   %rbp
  802e60:	48 89 e5             	mov    %rsp,%rbp
  802e63:	48 83 ec 10          	sub    $0x10,%rsp
  802e67:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802e6b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802e6f:	48 89 c7             	mov    %rax,%rdi
  802e72:	48 b8 12 13 80 00 00 	movabs $0x801312,%rax
  802e79:	00 00 00 
  802e7c:	ff d0                	callq  *%rax
  802e7e:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  802e83:	7e 07                	jle    802e8c <remove+0x2d>
  802e85:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  802e8a:	eb 33                	jmp    802ebf <remove+0x60>
  802e8c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802e90:	48 89 c6             	mov    %rax,%rsi
  802e93:	48 bf 00 80 80 00 00 	movabs $0x808000,%rdi
  802e9a:	00 00 00 
  802e9d:	48 b8 7e 13 80 00 00 	movabs $0x80137e,%rax
  802ea4:	00 00 00 
  802ea7:	ff d0                	callq  *%rax
  802ea9:	be 00 00 00 00       	mov    $0x0,%esi
  802eae:	bf 07 00 00 00       	mov    $0x7,%edi
  802eb3:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802eba:	00 00 00 
  802ebd:	ff d0                	callq  *%rax
  802ebf:	c9                   	leaveq 
  802ec0:	c3                   	retq   

0000000000802ec1 <sync>:
  802ec1:	55                   	push   %rbp
  802ec2:	48 89 e5             	mov    %rsp,%rbp
  802ec5:	be 00 00 00 00       	mov    $0x0,%esi
  802eca:	bf 08 00 00 00       	mov    $0x8,%edi
  802ecf:	48 b8 f4 29 80 00 00 	movabs $0x8029f4,%rax
  802ed6:	00 00 00 
  802ed9:	ff d0                	callq  *%rax
  802edb:	5d                   	pop    %rbp
  802edc:	c3                   	retq   

0000000000802edd <copy>:
  802edd:	55                   	push   %rbp
  802ede:	48 89 e5             	mov    %rsp,%rbp
  802ee1:	48 81 ec 20 02 00 00 	sub    $0x220,%rsp
  802ee8:	48 89 bd e8 fd ff ff 	mov    %rdi,-0x218(%rbp)
  802eef:	48 89 b5 e0 fd ff ff 	mov    %rsi,-0x220(%rbp)
  802ef6:	48 8b 85 e8 fd ff ff 	mov    -0x218(%rbp),%rax
  802efd:	be 00 00 00 00       	mov    $0x0,%esi
  802f02:	48 89 c7             	mov    %rax,%rdi
  802f05:	48 b8 7b 2a 80 00 00 	movabs $0x802a7b,%rax
  802f0c:	00 00 00 
  802f0f:	ff d0                	callq  *%rax
  802f11:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802f14:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802f18:	79 28                	jns    802f42 <copy+0x65>
  802f1a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802f1d:	89 c6                	mov    %eax,%esi
  802f1f:	48 bf cc 4c 80 00 00 	movabs $0x804ccc,%rdi
  802f26:	00 00 00 
  802f29:	b8 00 00 00 00       	mov    $0x0,%eax
  802f2e:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  802f35:	00 00 00 
  802f38:	ff d2                	callq  *%rdx
  802f3a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802f3d:	e9 74 01 00 00       	jmpq   8030b6 <copy+0x1d9>
  802f42:	48 8b 85 e0 fd ff ff 	mov    -0x220(%rbp),%rax
  802f49:	be 01 01 00 00       	mov    $0x101,%esi
  802f4e:	48 89 c7             	mov    %rax,%rdi
  802f51:	48 b8 7b 2a 80 00 00 	movabs $0x802a7b,%rax
  802f58:	00 00 00 
  802f5b:	ff d0                	callq  *%rax
  802f5d:	89 45 f8             	mov    %eax,-0x8(%rbp)
  802f60:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  802f64:	79 39                	jns    802f9f <copy+0xc2>
  802f66:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802f69:	89 c6                	mov    %eax,%esi
  802f6b:	48 bf e2 4c 80 00 00 	movabs $0x804ce2,%rdi
  802f72:	00 00 00 
  802f75:	b8 00 00 00 00       	mov    $0x0,%eax
  802f7a:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  802f81:	00 00 00 
  802f84:	ff d2                	callq  *%rdx
  802f86:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802f89:	89 c7                	mov    %eax,%edi
  802f8b:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  802f92:	00 00 00 
  802f95:	ff d0                	callq  *%rax
  802f97:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802f9a:	e9 17 01 00 00       	jmpq   8030b6 <copy+0x1d9>
  802f9f:	eb 74                	jmp    803015 <copy+0x138>
  802fa1:	8b 45 f4             	mov    -0xc(%rbp),%eax
  802fa4:	48 63 d0             	movslq %eax,%rdx
  802fa7:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  802fae:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802fb1:	48 89 ce             	mov    %rcx,%rsi
  802fb4:	89 c7                	mov    %eax,%edi
  802fb6:	48 b8 ef 26 80 00 00 	movabs $0x8026ef,%rax
  802fbd:	00 00 00 
  802fc0:	ff d0                	callq  *%rax
  802fc2:	89 45 f0             	mov    %eax,-0x10(%rbp)
  802fc5:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
  802fc9:	79 4a                	jns    803015 <copy+0x138>
  802fcb:	8b 45 f0             	mov    -0x10(%rbp),%eax
  802fce:	89 c6                	mov    %eax,%esi
  802fd0:	48 bf fc 4c 80 00 00 	movabs $0x804cfc,%rdi
  802fd7:	00 00 00 
  802fda:	b8 00 00 00 00       	mov    $0x0,%eax
  802fdf:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  802fe6:	00 00 00 
  802fe9:	ff d2                	callq  *%rdx
  802feb:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802fee:	89 c7                	mov    %eax,%edi
  802ff0:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  802ff7:	00 00 00 
  802ffa:	ff d0                	callq  *%rax
  802ffc:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802fff:	89 c7                	mov    %eax,%edi
  803001:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  803008:	00 00 00 
  80300b:	ff d0                	callq  *%rax
  80300d:	8b 45 f0             	mov    -0x10(%rbp),%eax
  803010:	e9 a1 00 00 00       	jmpq   8030b6 <copy+0x1d9>
  803015:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  80301c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80301f:	ba 00 02 00 00       	mov    $0x200,%edx
  803024:	48 89 ce             	mov    %rcx,%rsi
  803027:	89 c7                	mov    %eax,%edi
  803029:	48 b8 a5 25 80 00 00 	movabs $0x8025a5,%rax
  803030:	00 00 00 
  803033:	ff d0                	callq  *%rax
  803035:	89 45 f4             	mov    %eax,-0xc(%rbp)
  803038:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  80303c:	0f 8f 5f ff ff ff    	jg     802fa1 <copy+0xc4>
  803042:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  803046:	79 47                	jns    80308f <copy+0x1b2>
  803048:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80304b:	89 c6                	mov    %eax,%esi
  80304d:	48 bf 0f 4d 80 00 00 	movabs $0x804d0f,%rdi
  803054:	00 00 00 
  803057:	b8 00 00 00 00       	mov    $0x0,%eax
  80305c:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  803063:	00 00 00 
  803066:	ff d2                	callq  *%rdx
  803068:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80306b:	89 c7                	mov    %eax,%edi
  80306d:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  803074:	00 00 00 
  803077:	ff d0                	callq  *%rax
  803079:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80307c:	89 c7                	mov    %eax,%edi
  80307e:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  803085:	00 00 00 
  803088:	ff d0                	callq  *%rax
  80308a:	8b 45 f4             	mov    -0xc(%rbp),%eax
  80308d:	eb 27                	jmp    8030b6 <copy+0x1d9>
  80308f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803092:	89 c7                	mov    %eax,%edi
  803094:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  80309b:	00 00 00 
  80309e:	ff d0                	callq  *%rax
  8030a0:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8030a3:	89 c7                	mov    %eax,%edi
  8030a5:	48 b8 83 23 80 00 00 	movabs $0x802383,%rax
  8030ac:	00 00 00 
  8030af:	ff d0                	callq  *%rax
  8030b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8030b6:	c9                   	leaveq 
  8030b7:	c3                   	retq   

00000000008030b8 <fd2sockid>:
  8030b8:	55                   	push   %rbp
  8030b9:	48 89 e5             	mov    %rsp,%rbp
  8030bc:	48 83 ec 20          	sub    $0x20,%rsp
  8030c0:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8030c3:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8030c7:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8030ca:	48 89 d6             	mov    %rdx,%rsi
  8030cd:	89 c7                	mov    %eax,%edi
  8030cf:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  8030d6:	00 00 00 
  8030d9:	ff d0                	callq  *%rax
  8030db:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8030de:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8030e2:	79 05                	jns    8030e9 <fd2sockid+0x31>
  8030e4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8030e7:	eb 24                	jmp    80310d <fd2sockid+0x55>
  8030e9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8030ed:	8b 10                	mov    (%rax),%edx
  8030ef:	48 b8 a0 60 80 00 00 	movabs $0x8060a0,%rax
  8030f6:	00 00 00 
  8030f9:	8b 00                	mov    (%rax),%eax
  8030fb:	39 c2                	cmp    %eax,%edx
  8030fd:	74 07                	je     803106 <fd2sockid+0x4e>
  8030ff:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  803104:	eb 07                	jmp    80310d <fd2sockid+0x55>
  803106:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80310a:	8b 40 0c             	mov    0xc(%rax),%eax
  80310d:	c9                   	leaveq 
  80310e:	c3                   	retq   

000000000080310f <alloc_sockfd>:
  80310f:	55                   	push   %rbp
  803110:	48 89 e5             	mov    %rsp,%rbp
  803113:	48 83 ec 20          	sub    $0x20,%rsp
  803117:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80311a:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  80311e:	48 89 c7             	mov    %rax,%rdi
  803121:	48 b8 db 20 80 00 00 	movabs $0x8020db,%rax
  803128:	00 00 00 
  80312b:	ff d0                	callq  *%rax
  80312d:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803130:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803134:	78 26                	js     80315c <alloc_sockfd+0x4d>
  803136:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80313a:	ba 07 04 00 00       	mov    $0x407,%edx
  80313f:	48 89 c6             	mov    %rax,%rsi
  803142:	bf 00 00 00 00       	mov    $0x0,%edi
  803147:	48 b8 ad 1c 80 00 00 	movabs $0x801cad,%rax
  80314e:	00 00 00 
  803151:	ff d0                	callq  *%rax
  803153:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803156:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80315a:	79 16                	jns    803172 <alloc_sockfd+0x63>
  80315c:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80315f:	89 c7                	mov    %eax,%edi
  803161:	48 b8 1c 36 80 00 00 	movabs $0x80361c,%rax
  803168:	00 00 00 
  80316b:	ff d0                	callq  *%rax
  80316d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803170:	eb 3a                	jmp    8031ac <alloc_sockfd+0x9d>
  803172:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803176:	48 ba a0 60 80 00 00 	movabs $0x8060a0,%rdx
  80317d:	00 00 00 
  803180:	8b 12                	mov    (%rdx),%edx
  803182:	89 10                	mov    %edx,(%rax)
  803184:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803188:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  80318f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803193:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803196:	89 50 0c             	mov    %edx,0xc(%rax)
  803199:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80319d:	48 89 c7             	mov    %rax,%rdi
  8031a0:	48 b8 8d 20 80 00 00 	movabs $0x80208d,%rax
  8031a7:	00 00 00 
  8031aa:	ff d0                	callq  *%rax
  8031ac:	c9                   	leaveq 
  8031ad:	c3                   	retq   

00000000008031ae <accept>:
  8031ae:	55                   	push   %rbp
  8031af:	48 89 e5             	mov    %rsp,%rbp
  8031b2:	48 83 ec 30          	sub    $0x30,%rsp
  8031b6:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8031b9:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8031bd:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8031c1:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8031c4:	89 c7                	mov    %eax,%edi
  8031c6:	48 b8 b8 30 80 00 00 	movabs $0x8030b8,%rax
  8031cd:	00 00 00 
  8031d0:	ff d0                	callq  *%rax
  8031d2:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8031d5:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8031d9:	79 05                	jns    8031e0 <accept+0x32>
  8031db:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8031de:	eb 3b                	jmp    80321b <accept+0x6d>
  8031e0:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8031e4:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  8031e8:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8031eb:	48 89 ce             	mov    %rcx,%rsi
  8031ee:	89 c7                	mov    %eax,%edi
  8031f0:	48 b8 f9 34 80 00 00 	movabs $0x8034f9,%rax
  8031f7:	00 00 00 
  8031fa:	ff d0                	callq  *%rax
  8031fc:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8031ff:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803203:	79 05                	jns    80320a <accept+0x5c>
  803205:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803208:	eb 11                	jmp    80321b <accept+0x6d>
  80320a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80320d:	89 c7                	mov    %eax,%edi
  80320f:	48 b8 0f 31 80 00 00 	movabs $0x80310f,%rax
  803216:	00 00 00 
  803219:	ff d0                	callq  *%rax
  80321b:	c9                   	leaveq 
  80321c:	c3                   	retq   

000000000080321d <bind>:
  80321d:	55                   	push   %rbp
  80321e:	48 89 e5             	mov    %rsp,%rbp
  803221:	48 83 ec 20          	sub    $0x20,%rsp
  803225:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803228:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80322c:	89 55 e8             	mov    %edx,-0x18(%rbp)
  80322f:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803232:	89 c7                	mov    %eax,%edi
  803234:	48 b8 b8 30 80 00 00 	movabs $0x8030b8,%rax
  80323b:	00 00 00 
  80323e:	ff d0                	callq  *%rax
  803240:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803243:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803247:	79 05                	jns    80324e <bind+0x31>
  803249:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80324c:	eb 1b                	jmp    803269 <bind+0x4c>
  80324e:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803251:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  803255:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803258:	48 89 ce             	mov    %rcx,%rsi
  80325b:	89 c7                	mov    %eax,%edi
  80325d:	48 b8 78 35 80 00 00 	movabs $0x803578,%rax
  803264:	00 00 00 
  803267:	ff d0                	callq  *%rax
  803269:	c9                   	leaveq 
  80326a:	c3                   	retq   

000000000080326b <shutdown>:
  80326b:	55                   	push   %rbp
  80326c:	48 89 e5             	mov    %rsp,%rbp
  80326f:	48 83 ec 20          	sub    $0x20,%rsp
  803273:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803276:	89 75 e8             	mov    %esi,-0x18(%rbp)
  803279:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80327c:	89 c7                	mov    %eax,%edi
  80327e:	48 b8 b8 30 80 00 00 	movabs $0x8030b8,%rax
  803285:	00 00 00 
  803288:	ff d0                	callq  *%rax
  80328a:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80328d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803291:	79 05                	jns    803298 <shutdown+0x2d>
  803293:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803296:	eb 16                	jmp    8032ae <shutdown+0x43>
  803298:	8b 55 e8             	mov    -0x18(%rbp),%edx
  80329b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80329e:	89 d6                	mov    %edx,%esi
  8032a0:	89 c7                	mov    %eax,%edi
  8032a2:	48 b8 dc 35 80 00 00 	movabs $0x8035dc,%rax
  8032a9:	00 00 00 
  8032ac:	ff d0                	callq  *%rax
  8032ae:	c9                   	leaveq 
  8032af:	c3                   	retq   

00000000008032b0 <devsock_close>:
  8032b0:	55                   	push   %rbp
  8032b1:	48 89 e5             	mov    %rsp,%rbp
  8032b4:	48 83 ec 10          	sub    $0x10,%rsp
  8032b8:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8032bc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8032c0:	48 89 c7             	mov    %rax,%rdi
  8032c3:	48 b8 27 45 80 00 00 	movabs $0x804527,%rax
  8032ca:	00 00 00 
  8032cd:	ff d0                	callq  *%rax
  8032cf:	83 f8 01             	cmp    $0x1,%eax
  8032d2:	75 17                	jne    8032eb <devsock_close+0x3b>
  8032d4:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8032d8:	8b 40 0c             	mov    0xc(%rax),%eax
  8032db:	89 c7                	mov    %eax,%edi
  8032dd:	48 b8 1c 36 80 00 00 	movabs $0x80361c,%rax
  8032e4:	00 00 00 
  8032e7:	ff d0                	callq  *%rax
  8032e9:	eb 05                	jmp    8032f0 <devsock_close+0x40>
  8032eb:	b8 00 00 00 00       	mov    $0x0,%eax
  8032f0:	c9                   	leaveq 
  8032f1:	c3                   	retq   

00000000008032f2 <connect>:
  8032f2:	55                   	push   %rbp
  8032f3:	48 89 e5             	mov    %rsp,%rbp
  8032f6:	48 83 ec 20          	sub    $0x20,%rsp
  8032fa:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8032fd:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803301:	89 55 e8             	mov    %edx,-0x18(%rbp)
  803304:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803307:	89 c7                	mov    %eax,%edi
  803309:	48 b8 b8 30 80 00 00 	movabs $0x8030b8,%rax
  803310:	00 00 00 
  803313:	ff d0                	callq  *%rax
  803315:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803318:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80331c:	79 05                	jns    803323 <connect+0x31>
  80331e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803321:	eb 1b                	jmp    80333e <connect+0x4c>
  803323:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803326:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  80332a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80332d:	48 89 ce             	mov    %rcx,%rsi
  803330:	89 c7                	mov    %eax,%edi
  803332:	48 b8 49 36 80 00 00 	movabs $0x803649,%rax
  803339:	00 00 00 
  80333c:	ff d0                	callq  *%rax
  80333e:	c9                   	leaveq 
  80333f:	c3                   	retq   

0000000000803340 <listen>:
  803340:	55                   	push   %rbp
  803341:	48 89 e5             	mov    %rsp,%rbp
  803344:	48 83 ec 20          	sub    $0x20,%rsp
  803348:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80334b:	89 75 e8             	mov    %esi,-0x18(%rbp)
  80334e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803351:	89 c7                	mov    %eax,%edi
  803353:	48 b8 b8 30 80 00 00 	movabs $0x8030b8,%rax
  80335a:	00 00 00 
  80335d:	ff d0                	callq  *%rax
  80335f:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803362:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803366:	79 05                	jns    80336d <listen+0x2d>
  803368:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80336b:	eb 16                	jmp    803383 <listen+0x43>
  80336d:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803370:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803373:	89 d6                	mov    %edx,%esi
  803375:	89 c7                	mov    %eax,%edi
  803377:	48 b8 ad 36 80 00 00 	movabs $0x8036ad,%rax
  80337e:	00 00 00 
  803381:	ff d0                	callq  *%rax
  803383:	c9                   	leaveq 
  803384:	c3                   	retq   

0000000000803385 <devsock_read>:
  803385:	55                   	push   %rbp
  803386:	48 89 e5             	mov    %rsp,%rbp
  803389:	48 83 ec 20          	sub    $0x20,%rsp
  80338d:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803391:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803395:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  803399:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80339d:	89 c2                	mov    %eax,%edx
  80339f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8033a3:	8b 40 0c             	mov    0xc(%rax),%eax
  8033a6:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  8033aa:	b9 00 00 00 00       	mov    $0x0,%ecx
  8033af:	89 c7                	mov    %eax,%edi
  8033b1:	48 b8 ed 36 80 00 00 	movabs $0x8036ed,%rax
  8033b8:	00 00 00 
  8033bb:	ff d0                	callq  *%rax
  8033bd:	c9                   	leaveq 
  8033be:	c3                   	retq   

00000000008033bf <devsock_write>:
  8033bf:	55                   	push   %rbp
  8033c0:	48 89 e5             	mov    %rsp,%rbp
  8033c3:	48 83 ec 20          	sub    $0x20,%rsp
  8033c7:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8033cb:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8033cf:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8033d3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8033d7:	89 c2                	mov    %eax,%edx
  8033d9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8033dd:	8b 40 0c             	mov    0xc(%rax),%eax
  8033e0:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  8033e4:	b9 00 00 00 00       	mov    $0x0,%ecx
  8033e9:	89 c7                	mov    %eax,%edi
  8033eb:	48 b8 b9 37 80 00 00 	movabs $0x8037b9,%rax
  8033f2:	00 00 00 
  8033f5:	ff d0                	callq  *%rax
  8033f7:	c9                   	leaveq 
  8033f8:	c3                   	retq   

00000000008033f9 <devsock_stat>:
  8033f9:	55                   	push   %rbp
  8033fa:	48 89 e5             	mov    %rsp,%rbp
  8033fd:	48 83 ec 10          	sub    $0x10,%rsp
  803401:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803405:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803409:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80340d:	48 be 2a 4d 80 00 00 	movabs $0x804d2a,%rsi
  803414:	00 00 00 
  803417:	48 89 c7             	mov    %rax,%rdi
  80341a:	48 b8 7e 13 80 00 00 	movabs $0x80137e,%rax
  803421:	00 00 00 
  803424:	ff d0                	callq  *%rax
  803426:	b8 00 00 00 00       	mov    $0x0,%eax
  80342b:	c9                   	leaveq 
  80342c:	c3                   	retq   

000000000080342d <socket>:
  80342d:	55                   	push   %rbp
  80342e:	48 89 e5             	mov    %rsp,%rbp
  803431:	48 83 ec 20          	sub    $0x20,%rsp
  803435:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803438:	89 75 e8             	mov    %esi,-0x18(%rbp)
  80343b:	89 55 e4             	mov    %edx,-0x1c(%rbp)
  80343e:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  803441:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  803444:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803447:	89 ce                	mov    %ecx,%esi
  803449:	89 c7                	mov    %eax,%edi
  80344b:	48 b8 71 38 80 00 00 	movabs $0x803871,%rax
  803452:	00 00 00 
  803455:	ff d0                	callq  *%rax
  803457:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80345a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80345e:	79 05                	jns    803465 <socket+0x38>
  803460:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803463:	eb 11                	jmp    803476 <socket+0x49>
  803465:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803468:	89 c7                	mov    %eax,%edi
  80346a:	48 b8 0f 31 80 00 00 	movabs $0x80310f,%rax
  803471:	00 00 00 
  803474:	ff d0                	callq  *%rax
  803476:	c9                   	leaveq 
  803477:	c3                   	retq   

0000000000803478 <nsipc>:
  803478:	55                   	push   %rbp
  803479:	48 89 e5             	mov    %rsp,%rbp
  80347c:	48 83 ec 10          	sub    $0x10,%rsp
  803480:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803483:	48 b8 04 70 80 00 00 	movabs $0x807004,%rax
  80348a:	00 00 00 
  80348d:	8b 00                	mov    (%rax),%eax
  80348f:	85 c0                	test   %eax,%eax
  803491:	75 1d                	jne    8034b0 <nsipc+0x38>
  803493:	bf 02 00 00 00       	mov    $0x2,%edi
  803498:	48 b8 b5 44 80 00 00 	movabs $0x8044b5,%rax
  80349f:	00 00 00 
  8034a2:	ff d0                	callq  *%rax
  8034a4:	48 ba 04 70 80 00 00 	movabs $0x807004,%rdx
  8034ab:	00 00 00 
  8034ae:	89 02                	mov    %eax,(%rdx)
  8034b0:	48 b8 04 70 80 00 00 	movabs $0x807004,%rax
  8034b7:	00 00 00 
  8034ba:	8b 00                	mov    (%rax),%eax
  8034bc:	8b 75 fc             	mov    -0x4(%rbp),%esi
  8034bf:	b9 07 00 00 00       	mov    $0x7,%ecx
  8034c4:	48 ba 00 a0 80 00 00 	movabs $0x80a000,%rdx
  8034cb:	00 00 00 
  8034ce:	89 c7                	mov    %eax,%edi
  8034d0:	48 b8 aa 43 80 00 00 	movabs $0x8043aa,%rax
  8034d7:	00 00 00 
  8034da:	ff d0                	callq  *%rax
  8034dc:	ba 00 00 00 00       	mov    $0x0,%edx
  8034e1:	be 00 00 00 00       	mov    $0x0,%esi
  8034e6:	bf 00 00 00 00       	mov    $0x0,%edi
  8034eb:	48 b8 e9 42 80 00 00 	movabs $0x8042e9,%rax
  8034f2:	00 00 00 
  8034f5:	ff d0                	callq  *%rax
  8034f7:	c9                   	leaveq 
  8034f8:	c3                   	retq   

00000000008034f9 <nsipc_accept>:
  8034f9:	55                   	push   %rbp
  8034fa:	48 89 e5             	mov    %rsp,%rbp
  8034fd:	48 83 ec 30          	sub    $0x30,%rsp
  803501:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803504:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803508:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80350c:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803513:	00 00 00 
  803516:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803519:	89 10                	mov    %edx,(%rax)
  80351b:	bf 01 00 00 00       	mov    $0x1,%edi
  803520:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  803527:	00 00 00 
  80352a:	ff d0                	callq  *%rax
  80352c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80352f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803533:	78 3e                	js     803573 <nsipc_accept+0x7a>
  803535:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80353c:	00 00 00 
  80353f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803543:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803547:	8b 40 10             	mov    0x10(%rax),%eax
  80354a:	89 c2                	mov    %eax,%edx
  80354c:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  803550:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803554:	48 89 ce             	mov    %rcx,%rsi
  803557:	48 89 c7             	mov    %rax,%rdi
  80355a:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  803561:	00 00 00 
  803564:	ff d0                	callq  *%rax
  803566:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80356a:	8b 50 10             	mov    0x10(%rax),%edx
  80356d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803571:	89 10                	mov    %edx,(%rax)
  803573:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803576:	c9                   	leaveq 
  803577:	c3                   	retq   

0000000000803578 <nsipc_bind>:
  803578:	55                   	push   %rbp
  803579:	48 89 e5             	mov    %rsp,%rbp
  80357c:	48 83 ec 10          	sub    $0x10,%rsp
  803580:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803583:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803587:	89 55 f8             	mov    %edx,-0x8(%rbp)
  80358a:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803591:	00 00 00 
  803594:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803597:	89 10                	mov    %edx,(%rax)
  803599:	8b 55 f8             	mov    -0x8(%rbp),%edx
  80359c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8035a0:	48 89 c6             	mov    %rax,%rsi
  8035a3:	48 bf 04 a0 80 00 00 	movabs $0x80a004,%rdi
  8035aa:	00 00 00 
  8035ad:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  8035b4:	00 00 00 
  8035b7:	ff d0                	callq  *%rax
  8035b9:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8035c0:	00 00 00 
  8035c3:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8035c6:	89 50 14             	mov    %edx,0x14(%rax)
  8035c9:	bf 02 00 00 00       	mov    $0x2,%edi
  8035ce:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  8035d5:	00 00 00 
  8035d8:	ff d0                	callq  *%rax
  8035da:	c9                   	leaveq 
  8035db:	c3                   	retq   

00000000008035dc <nsipc_shutdown>:
  8035dc:	55                   	push   %rbp
  8035dd:	48 89 e5             	mov    %rsp,%rbp
  8035e0:	48 83 ec 10          	sub    $0x10,%rsp
  8035e4:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8035e7:	89 75 f8             	mov    %esi,-0x8(%rbp)
  8035ea:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8035f1:	00 00 00 
  8035f4:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8035f7:	89 10                	mov    %edx,(%rax)
  8035f9:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803600:	00 00 00 
  803603:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803606:	89 50 04             	mov    %edx,0x4(%rax)
  803609:	bf 03 00 00 00       	mov    $0x3,%edi
  80360e:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  803615:	00 00 00 
  803618:	ff d0                	callq  *%rax
  80361a:	c9                   	leaveq 
  80361b:	c3                   	retq   

000000000080361c <nsipc_close>:
  80361c:	55                   	push   %rbp
  80361d:	48 89 e5             	mov    %rsp,%rbp
  803620:	48 83 ec 10          	sub    $0x10,%rsp
  803624:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803627:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  80362e:	00 00 00 
  803631:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803634:	89 10                	mov    %edx,(%rax)
  803636:	bf 04 00 00 00       	mov    $0x4,%edi
  80363b:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  803642:	00 00 00 
  803645:	ff d0                	callq  *%rax
  803647:	c9                   	leaveq 
  803648:	c3                   	retq   

0000000000803649 <nsipc_connect>:
  803649:	55                   	push   %rbp
  80364a:	48 89 e5             	mov    %rsp,%rbp
  80364d:	48 83 ec 10          	sub    $0x10,%rsp
  803651:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803654:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803658:	89 55 f8             	mov    %edx,-0x8(%rbp)
  80365b:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803662:	00 00 00 
  803665:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803668:	89 10                	mov    %edx,(%rax)
  80366a:	8b 55 f8             	mov    -0x8(%rbp),%edx
  80366d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803671:	48 89 c6             	mov    %rax,%rsi
  803674:	48 bf 04 a0 80 00 00 	movabs $0x80a004,%rdi
  80367b:	00 00 00 
  80367e:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  803685:	00 00 00 
  803688:	ff d0                	callq  *%rax
  80368a:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803691:	00 00 00 
  803694:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803697:	89 50 14             	mov    %edx,0x14(%rax)
  80369a:	bf 05 00 00 00       	mov    $0x5,%edi
  80369f:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  8036a6:	00 00 00 
  8036a9:	ff d0                	callq  *%rax
  8036ab:	c9                   	leaveq 
  8036ac:	c3                   	retq   

00000000008036ad <nsipc_listen>:
  8036ad:	55                   	push   %rbp
  8036ae:	48 89 e5             	mov    %rsp,%rbp
  8036b1:	48 83 ec 10          	sub    $0x10,%rsp
  8036b5:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8036b8:	89 75 f8             	mov    %esi,-0x8(%rbp)
  8036bb:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8036c2:	00 00 00 
  8036c5:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8036c8:	89 10                	mov    %edx,(%rax)
  8036ca:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8036d1:	00 00 00 
  8036d4:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8036d7:	89 50 04             	mov    %edx,0x4(%rax)
  8036da:	bf 06 00 00 00       	mov    $0x6,%edi
  8036df:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  8036e6:	00 00 00 
  8036e9:	ff d0                	callq  *%rax
  8036eb:	c9                   	leaveq 
  8036ec:	c3                   	retq   

00000000008036ed <nsipc_recv>:
  8036ed:	55                   	push   %rbp
  8036ee:	48 89 e5             	mov    %rsp,%rbp
  8036f1:	48 83 ec 30          	sub    $0x30,%rsp
  8036f5:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8036f8:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8036fc:	89 55 e8             	mov    %edx,-0x18(%rbp)
  8036ff:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  803702:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803709:	00 00 00 
  80370c:	8b 55 ec             	mov    -0x14(%rbp),%edx
  80370f:	89 10                	mov    %edx,(%rax)
  803711:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803718:	00 00 00 
  80371b:	8b 55 e8             	mov    -0x18(%rbp),%edx
  80371e:	89 50 04             	mov    %edx,0x4(%rax)
  803721:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803728:	00 00 00 
  80372b:	8b 55 dc             	mov    -0x24(%rbp),%edx
  80372e:	89 50 08             	mov    %edx,0x8(%rax)
  803731:	bf 07 00 00 00       	mov    $0x7,%edi
  803736:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  80373d:	00 00 00 
  803740:	ff d0                	callq  *%rax
  803742:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803745:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803749:	78 69                	js     8037b4 <nsipc_recv+0xc7>
  80374b:	81 7d fc 3f 06 00 00 	cmpl   $0x63f,-0x4(%rbp)
  803752:	7f 08                	jg     80375c <nsipc_recv+0x6f>
  803754:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803757:	3b 45 e8             	cmp    -0x18(%rbp),%eax
  80375a:	7e 35                	jle    803791 <nsipc_recv+0xa4>
  80375c:	48 b9 31 4d 80 00 00 	movabs $0x804d31,%rcx
  803763:	00 00 00 
  803766:	48 ba 46 4d 80 00 00 	movabs $0x804d46,%rdx
  80376d:	00 00 00 
  803770:	be 62 00 00 00       	mov    $0x62,%esi
  803775:	48 bf 5b 4d 80 00 00 	movabs $0x804d5b,%rdi
  80377c:	00 00 00 
  80377f:	b8 00 00 00 00       	mov    $0x0,%eax
  803784:	49 b8 d5 41 80 00 00 	movabs $0x8041d5,%r8
  80378b:	00 00 00 
  80378e:	41 ff d0             	callq  *%r8
  803791:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803794:	48 63 d0             	movslq %eax,%rdx
  803797:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80379b:	48 be 00 a0 80 00 00 	movabs $0x80a000,%rsi
  8037a2:	00 00 00 
  8037a5:	48 89 c7             	mov    %rax,%rdi
  8037a8:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  8037af:	00 00 00 
  8037b2:	ff d0                	callq  *%rax
  8037b4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8037b7:	c9                   	leaveq 
  8037b8:	c3                   	retq   

00000000008037b9 <nsipc_send>:
  8037b9:	55                   	push   %rbp
  8037ba:	48 89 e5             	mov    %rsp,%rbp
  8037bd:	48 83 ec 20          	sub    $0x20,%rsp
  8037c1:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8037c4:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8037c8:	89 55 f8             	mov    %edx,-0x8(%rbp)
  8037cb:	89 4d ec             	mov    %ecx,-0x14(%rbp)
  8037ce:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8037d5:	00 00 00 
  8037d8:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8037db:	89 10                	mov    %edx,(%rax)
  8037dd:	81 7d f8 3f 06 00 00 	cmpl   $0x63f,-0x8(%rbp)
  8037e4:	7e 35                	jle    80381b <nsipc_send+0x62>
  8037e6:	48 b9 6a 4d 80 00 00 	movabs $0x804d6a,%rcx
  8037ed:	00 00 00 
  8037f0:	48 ba 46 4d 80 00 00 	movabs $0x804d46,%rdx
  8037f7:	00 00 00 
  8037fa:	be 6d 00 00 00       	mov    $0x6d,%esi
  8037ff:	48 bf 5b 4d 80 00 00 	movabs $0x804d5b,%rdi
  803806:	00 00 00 
  803809:	b8 00 00 00 00       	mov    $0x0,%eax
  80380e:	49 b8 d5 41 80 00 00 	movabs $0x8041d5,%r8
  803815:	00 00 00 
  803818:	41 ff d0             	callq  *%r8
  80381b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80381e:	48 63 d0             	movslq %eax,%rdx
  803821:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803825:	48 89 c6             	mov    %rax,%rsi
  803828:	48 bf 0c a0 80 00 00 	movabs $0x80a00c,%rdi
  80382f:	00 00 00 
  803832:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  803839:	00 00 00 
  80383c:	ff d0                	callq  *%rax
  80383e:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803845:	00 00 00 
  803848:	8b 55 f8             	mov    -0x8(%rbp),%edx
  80384b:	89 50 04             	mov    %edx,0x4(%rax)
  80384e:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803855:	00 00 00 
  803858:	8b 55 ec             	mov    -0x14(%rbp),%edx
  80385b:	89 50 08             	mov    %edx,0x8(%rax)
  80385e:	bf 08 00 00 00       	mov    $0x8,%edi
  803863:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  80386a:	00 00 00 
  80386d:	ff d0                	callq  *%rax
  80386f:	c9                   	leaveq 
  803870:	c3                   	retq   

0000000000803871 <nsipc_socket>:
  803871:	55                   	push   %rbp
  803872:	48 89 e5             	mov    %rsp,%rbp
  803875:	48 83 ec 10          	sub    $0x10,%rsp
  803879:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80387c:	89 75 f8             	mov    %esi,-0x8(%rbp)
  80387f:	89 55 f4             	mov    %edx,-0xc(%rbp)
  803882:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803889:	00 00 00 
  80388c:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80388f:	89 10                	mov    %edx,(%rax)
  803891:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  803898:	00 00 00 
  80389b:	8b 55 f8             	mov    -0x8(%rbp),%edx
  80389e:	89 50 04             	mov    %edx,0x4(%rax)
  8038a1:	48 b8 00 a0 80 00 00 	movabs $0x80a000,%rax
  8038a8:	00 00 00 
  8038ab:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8038ae:	89 50 08             	mov    %edx,0x8(%rax)
  8038b1:	bf 09 00 00 00       	mov    $0x9,%edi
  8038b6:	48 b8 78 34 80 00 00 	movabs $0x803478,%rax
  8038bd:	00 00 00 
  8038c0:	ff d0                	callq  *%rax
  8038c2:	c9                   	leaveq 
  8038c3:	c3                   	retq   

00000000008038c4 <pipe>:
  8038c4:	55                   	push   %rbp
  8038c5:	48 89 e5             	mov    %rsp,%rbp
  8038c8:	53                   	push   %rbx
  8038c9:	48 83 ec 38          	sub    $0x38,%rsp
  8038cd:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8038d1:	48 8d 45 d8          	lea    -0x28(%rbp),%rax
  8038d5:	48 89 c7             	mov    %rax,%rdi
  8038d8:	48 b8 db 20 80 00 00 	movabs $0x8020db,%rax
  8038df:	00 00 00 
  8038e2:	ff d0                	callq  *%rax
  8038e4:	89 45 ec             	mov    %eax,-0x14(%rbp)
  8038e7:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  8038eb:	0f 88 bf 01 00 00    	js     803ab0 <pipe+0x1ec>
  8038f1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8038f5:	ba 07 04 00 00       	mov    $0x407,%edx
  8038fa:	48 89 c6             	mov    %rax,%rsi
  8038fd:	bf 00 00 00 00       	mov    $0x0,%edi
  803902:	48 b8 ad 1c 80 00 00 	movabs $0x801cad,%rax
  803909:	00 00 00 
  80390c:	ff d0                	callq  *%rax
  80390e:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803911:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803915:	0f 88 95 01 00 00    	js     803ab0 <pipe+0x1ec>
  80391b:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  80391f:	48 89 c7             	mov    %rax,%rdi
  803922:	48 b8 db 20 80 00 00 	movabs $0x8020db,%rax
  803929:	00 00 00 
  80392c:	ff d0                	callq  *%rax
  80392e:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803931:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803935:	0f 88 5d 01 00 00    	js     803a98 <pipe+0x1d4>
  80393b:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80393f:	ba 07 04 00 00       	mov    $0x407,%edx
  803944:	48 89 c6             	mov    %rax,%rsi
  803947:	bf 00 00 00 00       	mov    $0x0,%edi
  80394c:	48 b8 ad 1c 80 00 00 	movabs $0x801cad,%rax
  803953:	00 00 00 
  803956:	ff d0                	callq  *%rax
  803958:	89 45 ec             	mov    %eax,-0x14(%rbp)
  80395b:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  80395f:	0f 88 33 01 00 00    	js     803a98 <pipe+0x1d4>
  803965:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803969:	48 89 c7             	mov    %rax,%rdi
  80396c:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  803973:	00 00 00 
  803976:	ff d0                	callq  *%rax
  803978:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  80397c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803980:	ba 07 04 00 00       	mov    $0x407,%edx
  803985:	48 89 c6             	mov    %rax,%rsi
  803988:	bf 00 00 00 00       	mov    $0x0,%edi
  80398d:	48 b8 ad 1c 80 00 00 	movabs $0x801cad,%rax
  803994:	00 00 00 
  803997:	ff d0                	callq  *%rax
  803999:	89 45 ec             	mov    %eax,-0x14(%rbp)
  80399c:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  8039a0:	79 05                	jns    8039a7 <pipe+0xe3>
  8039a2:	e9 d9 00 00 00       	jmpq   803a80 <pipe+0x1bc>
  8039a7:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  8039ab:	48 89 c7             	mov    %rax,%rdi
  8039ae:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  8039b5:	00 00 00 
  8039b8:	ff d0                	callq  *%rax
  8039ba:	48 89 c2             	mov    %rax,%rdx
  8039bd:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8039c1:	41 b8 07 04 00 00    	mov    $0x407,%r8d
  8039c7:	48 89 d1             	mov    %rdx,%rcx
  8039ca:	ba 00 00 00 00       	mov    $0x0,%edx
  8039cf:	48 89 c6             	mov    %rax,%rsi
  8039d2:	bf 00 00 00 00       	mov    $0x0,%edi
  8039d7:	48 b8 fd 1c 80 00 00 	movabs $0x801cfd,%rax
  8039de:	00 00 00 
  8039e1:	ff d0                	callq  *%rax
  8039e3:	89 45 ec             	mov    %eax,-0x14(%rbp)
  8039e6:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  8039ea:	79 1b                	jns    803a07 <pipe+0x143>
  8039ec:	90                   	nop
  8039ed:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8039f1:	48 89 c6             	mov    %rax,%rsi
  8039f4:	bf 00 00 00 00       	mov    $0x0,%edi
  8039f9:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  803a00:	00 00 00 
  803a03:	ff d0                	callq  *%rax
  803a05:	eb 79                	jmp    803a80 <pipe+0x1bc>
  803a07:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803a0b:	48 ba e0 60 80 00 00 	movabs $0x8060e0,%rdx
  803a12:	00 00 00 
  803a15:	8b 12                	mov    (%rdx),%edx
  803a17:	89 10                	mov    %edx,(%rax)
  803a19:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803a1d:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%rax)
  803a24:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803a28:	48 ba e0 60 80 00 00 	movabs $0x8060e0,%rdx
  803a2f:	00 00 00 
  803a32:	8b 12                	mov    (%rdx),%edx
  803a34:	89 10                	mov    %edx,(%rax)
  803a36:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803a3a:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%rax)
  803a41:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803a45:	48 89 c7             	mov    %rax,%rdi
  803a48:	48 b8 8d 20 80 00 00 	movabs $0x80208d,%rax
  803a4f:	00 00 00 
  803a52:	ff d0                	callq  *%rax
  803a54:	89 c2                	mov    %eax,%edx
  803a56:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803a5a:	89 10                	mov    %edx,(%rax)
  803a5c:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803a60:	48 8d 58 04          	lea    0x4(%rax),%rbx
  803a64:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803a68:	48 89 c7             	mov    %rax,%rdi
  803a6b:	48 b8 8d 20 80 00 00 	movabs $0x80208d,%rax
  803a72:	00 00 00 
  803a75:	ff d0                	callq  *%rax
  803a77:	89 03                	mov    %eax,(%rbx)
  803a79:	b8 00 00 00 00       	mov    $0x0,%eax
  803a7e:	eb 33                	jmp    803ab3 <pipe+0x1ef>
  803a80:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803a84:	48 89 c6             	mov    %rax,%rsi
  803a87:	bf 00 00 00 00       	mov    $0x0,%edi
  803a8c:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  803a93:	00 00 00 
  803a96:	ff d0                	callq  *%rax
  803a98:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803a9c:	48 89 c6             	mov    %rax,%rsi
  803a9f:	bf 00 00 00 00       	mov    $0x0,%edi
  803aa4:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  803aab:	00 00 00 
  803aae:	ff d0                	callq  *%rax
  803ab0:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803ab3:	48 83 c4 38          	add    $0x38,%rsp
  803ab7:	5b                   	pop    %rbx
  803ab8:	5d                   	pop    %rbp
  803ab9:	c3                   	retq   

0000000000803aba <_pipeisclosed>:
  803aba:	55                   	push   %rbp
  803abb:	48 89 e5             	mov    %rsp,%rbp
  803abe:	53                   	push   %rbx
  803abf:	48 83 ec 28          	sub    $0x28,%rsp
  803ac3:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803ac7:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803acb:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803ad2:	00 00 00 
  803ad5:	48 8b 00             	mov    (%rax),%rax
  803ad8:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803ade:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803ae1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803ae5:	48 89 c7             	mov    %rax,%rdi
  803ae8:	48 b8 27 45 80 00 00 	movabs $0x804527,%rax
  803aef:	00 00 00 
  803af2:	ff d0                	callq  *%rax
  803af4:	89 c3                	mov    %eax,%ebx
  803af6:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803afa:	48 89 c7             	mov    %rax,%rdi
  803afd:	48 b8 27 45 80 00 00 	movabs $0x804527,%rax
  803b04:	00 00 00 
  803b07:	ff d0                	callq  *%rax
  803b09:	39 c3                	cmp    %eax,%ebx
  803b0b:	0f 94 c0             	sete   %al
  803b0e:	0f b6 c0             	movzbl %al,%eax
  803b11:	89 45 e8             	mov    %eax,-0x18(%rbp)
  803b14:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803b1b:	00 00 00 
  803b1e:	48 8b 00             	mov    (%rax),%rax
  803b21:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803b27:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  803b2a:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803b2d:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803b30:	75 05                	jne    803b37 <_pipeisclosed+0x7d>
  803b32:	8b 45 e8             	mov    -0x18(%rbp),%eax
  803b35:	eb 4f                	jmp    803b86 <_pipeisclosed+0xcc>
  803b37:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803b3a:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803b3d:	74 42                	je     803b81 <_pipeisclosed+0xc7>
  803b3f:	83 7d e8 01          	cmpl   $0x1,-0x18(%rbp)
  803b43:	75 3c                	jne    803b81 <_pipeisclosed+0xc7>
  803b45:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  803b4c:	00 00 00 
  803b4f:	48 8b 00             	mov    (%rax),%rax
  803b52:	8b 90 d8 00 00 00    	mov    0xd8(%rax),%edx
  803b58:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  803b5b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803b5e:	89 c6                	mov    %eax,%esi
  803b60:	48 bf 7b 4d 80 00 00 	movabs $0x804d7b,%rdi
  803b67:	00 00 00 
  803b6a:	b8 00 00 00 00       	mov    $0x0,%eax
  803b6f:	49 b8 c9 07 80 00 00 	movabs $0x8007c9,%r8
  803b76:	00 00 00 
  803b79:	41 ff d0             	callq  *%r8
  803b7c:	e9 4a ff ff ff       	jmpq   803acb <_pipeisclosed+0x11>
  803b81:	e9 45 ff ff ff       	jmpq   803acb <_pipeisclosed+0x11>
  803b86:	48 83 c4 28          	add    $0x28,%rsp
  803b8a:	5b                   	pop    %rbx
  803b8b:	5d                   	pop    %rbp
  803b8c:	c3                   	retq   

0000000000803b8d <pipeisclosed>:
  803b8d:	55                   	push   %rbp
  803b8e:	48 89 e5             	mov    %rsp,%rbp
  803b91:	48 83 ec 30          	sub    $0x30,%rsp
  803b95:	89 7d dc             	mov    %edi,-0x24(%rbp)
  803b98:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  803b9c:	8b 45 dc             	mov    -0x24(%rbp),%eax
  803b9f:	48 89 d6             	mov    %rdx,%rsi
  803ba2:	89 c7                	mov    %eax,%edi
  803ba4:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  803bab:	00 00 00 
  803bae:	ff d0                	callq  *%rax
  803bb0:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803bb3:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803bb7:	79 05                	jns    803bbe <pipeisclosed+0x31>
  803bb9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803bbc:	eb 31                	jmp    803bef <pipeisclosed+0x62>
  803bbe:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803bc2:	48 89 c7             	mov    %rax,%rdi
  803bc5:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  803bcc:	00 00 00 
  803bcf:	ff d0                	callq  *%rax
  803bd1:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803bd5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803bd9:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803bdd:	48 89 d6             	mov    %rdx,%rsi
  803be0:	48 89 c7             	mov    %rax,%rdi
  803be3:	48 b8 ba 3a 80 00 00 	movabs $0x803aba,%rax
  803bea:	00 00 00 
  803bed:	ff d0                	callq  *%rax
  803bef:	c9                   	leaveq 
  803bf0:	c3                   	retq   

0000000000803bf1 <devpipe_read>:
  803bf1:	55                   	push   %rbp
  803bf2:	48 89 e5             	mov    %rsp,%rbp
  803bf5:	48 83 ec 40          	sub    $0x40,%rsp
  803bf9:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803bfd:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803c01:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  803c05:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803c09:	48 89 c7             	mov    %rax,%rdi
  803c0c:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  803c13:	00 00 00 
  803c16:	ff d0                	callq  *%rax
  803c18:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803c1c:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803c20:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  803c24:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  803c2b:	00 
  803c2c:	e9 92 00 00 00       	jmpq   803cc3 <devpipe_read+0xd2>
  803c31:	eb 41                	jmp    803c74 <devpipe_read+0x83>
  803c33:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  803c38:	74 09                	je     803c43 <devpipe_read+0x52>
  803c3a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803c3e:	e9 92 00 00 00       	jmpq   803cd5 <devpipe_read+0xe4>
  803c43:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803c47:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803c4b:	48 89 d6             	mov    %rdx,%rsi
  803c4e:	48 89 c7             	mov    %rax,%rdi
  803c51:	48 b8 ba 3a 80 00 00 	movabs $0x803aba,%rax
  803c58:	00 00 00 
  803c5b:	ff d0                	callq  *%rax
  803c5d:	85 c0                	test   %eax,%eax
  803c5f:	74 07                	je     803c68 <devpipe_read+0x77>
  803c61:	b8 00 00 00 00       	mov    $0x0,%eax
  803c66:	eb 6d                	jmp    803cd5 <devpipe_read+0xe4>
  803c68:	48 b8 6f 1c 80 00 00 	movabs $0x801c6f,%rax
  803c6f:	00 00 00 
  803c72:	ff d0                	callq  *%rax
  803c74:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803c78:	8b 10                	mov    (%rax),%edx
  803c7a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803c7e:	8b 40 04             	mov    0x4(%rax),%eax
  803c81:	39 c2                	cmp    %eax,%edx
  803c83:	74 ae                	je     803c33 <devpipe_read+0x42>
  803c85:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803c89:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  803c8d:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  803c91:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803c95:	8b 00                	mov    (%rax),%eax
  803c97:	99                   	cltd   
  803c98:	c1 ea 1b             	shr    $0x1b,%edx
  803c9b:	01 d0                	add    %edx,%eax
  803c9d:	83 e0 1f             	and    $0x1f,%eax
  803ca0:	29 d0                	sub    %edx,%eax
  803ca2:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803ca6:	48 98                	cltq   
  803ca8:	0f b6 44 02 08       	movzbl 0x8(%rdx,%rax,1),%eax
  803cad:	88 01                	mov    %al,(%rcx)
  803caf:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803cb3:	8b 00                	mov    (%rax),%eax
  803cb5:	8d 50 01             	lea    0x1(%rax),%edx
  803cb8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803cbc:	89 10                	mov    %edx,(%rax)
  803cbe:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  803cc3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803cc7:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  803ccb:	0f 82 60 ff ff ff    	jb     803c31 <devpipe_read+0x40>
  803cd1:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803cd5:	c9                   	leaveq 
  803cd6:	c3                   	retq   

0000000000803cd7 <devpipe_write>:
  803cd7:	55                   	push   %rbp
  803cd8:	48 89 e5             	mov    %rsp,%rbp
  803cdb:	48 83 ec 40          	sub    $0x40,%rsp
  803cdf:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803ce3:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803ce7:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  803ceb:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803cef:	48 89 c7             	mov    %rax,%rdi
  803cf2:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  803cf9:	00 00 00 
  803cfc:	ff d0                	callq  *%rax
  803cfe:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803d02:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803d06:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  803d0a:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  803d11:	00 
  803d12:	e9 8e 00 00 00       	jmpq   803da5 <devpipe_write+0xce>
  803d17:	eb 31                	jmp    803d4a <devpipe_write+0x73>
  803d19:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803d1d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803d21:	48 89 d6             	mov    %rdx,%rsi
  803d24:	48 89 c7             	mov    %rax,%rdi
  803d27:	48 b8 ba 3a 80 00 00 	movabs $0x803aba,%rax
  803d2e:	00 00 00 
  803d31:	ff d0                	callq  *%rax
  803d33:	85 c0                	test   %eax,%eax
  803d35:	74 07                	je     803d3e <devpipe_write+0x67>
  803d37:	b8 00 00 00 00       	mov    $0x0,%eax
  803d3c:	eb 79                	jmp    803db7 <devpipe_write+0xe0>
  803d3e:	48 b8 6f 1c 80 00 00 	movabs $0x801c6f,%rax
  803d45:	00 00 00 
  803d48:	ff d0                	callq  *%rax
  803d4a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803d4e:	8b 40 04             	mov    0x4(%rax),%eax
  803d51:	48 63 d0             	movslq %eax,%rdx
  803d54:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803d58:	8b 00                	mov    (%rax),%eax
  803d5a:	48 98                	cltq   
  803d5c:	48 83 c0 20          	add    $0x20,%rax
  803d60:	48 39 c2             	cmp    %rax,%rdx
  803d63:	73 b4                	jae    803d19 <devpipe_write+0x42>
  803d65:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803d69:	8b 40 04             	mov    0x4(%rax),%eax
  803d6c:	99                   	cltd   
  803d6d:	c1 ea 1b             	shr    $0x1b,%edx
  803d70:	01 d0                	add    %edx,%eax
  803d72:	83 e0 1f             	and    $0x1f,%eax
  803d75:	29 d0                	sub    %edx,%eax
  803d77:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  803d7b:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  803d7f:	48 01 ca             	add    %rcx,%rdx
  803d82:	0f b6 0a             	movzbl (%rdx),%ecx
  803d85:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803d89:	48 98                	cltq   
  803d8b:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  803d8f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803d93:	8b 40 04             	mov    0x4(%rax),%eax
  803d96:	8d 50 01             	lea    0x1(%rax),%edx
  803d99:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803d9d:	89 50 04             	mov    %edx,0x4(%rax)
  803da0:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  803da5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803da9:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  803dad:	0f 82 64 ff ff ff    	jb     803d17 <devpipe_write+0x40>
  803db3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803db7:	c9                   	leaveq 
  803db8:	c3                   	retq   

0000000000803db9 <devpipe_stat>:
  803db9:	55                   	push   %rbp
  803dba:	48 89 e5             	mov    %rsp,%rbp
  803dbd:	48 83 ec 20          	sub    $0x20,%rsp
  803dc1:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  803dc5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803dc9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803dcd:	48 89 c7             	mov    %rax,%rdi
  803dd0:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  803dd7:	00 00 00 
  803dda:	ff d0                	callq  *%rax
  803ddc:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  803de0:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803de4:	48 be 8e 4d 80 00 00 	movabs $0x804d8e,%rsi
  803deb:	00 00 00 
  803dee:	48 89 c7             	mov    %rax,%rdi
  803df1:	48 b8 7e 13 80 00 00 	movabs $0x80137e,%rax
  803df8:	00 00 00 
  803dfb:	ff d0                	callq  *%rax
  803dfd:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e01:	8b 50 04             	mov    0x4(%rax),%edx
  803e04:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e08:	8b 00                	mov    (%rax),%eax
  803e0a:	29 c2                	sub    %eax,%edx
  803e0c:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803e10:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  803e16:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803e1a:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  803e21:	00 00 00 
  803e24:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803e28:	48 b9 e0 60 80 00 00 	movabs $0x8060e0,%rcx
  803e2f:	00 00 00 
  803e32:	48 89 88 88 00 00 00 	mov    %rcx,0x88(%rax)
  803e39:	b8 00 00 00 00       	mov    $0x0,%eax
  803e3e:	c9                   	leaveq 
  803e3f:	c3                   	retq   

0000000000803e40 <devpipe_close>:
  803e40:	55                   	push   %rbp
  803e41:	48 89 e5             	mov    %rsp,%rbp
  803e44:	48 83 ec 10          	sub    $0x10,%rsp
  803e48:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803e4c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e50:	48 89 c6             	mov    %rax,%rsi
  803e53:	bf 00 00 00 00       	mov    $0x0,%edi
  803e58:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  803e5f:	00 00 00 
  803e62:	ff d0                	callq  *%rax
  803e64:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803e68:	48 89 c7             	mov    %rax,%rdi
  803e6b:	48 b8 b0 20 80 00 00 	movabs $0x8020b0,%rax
  803e72:	00 00 00 
  803e75:	ff d0                	callq  *%rax
  803e77:	48 89 c6             	mov    %rax,%rsi
  803e7a:	bf 00 00 00 00       	mov    $0x0,%edi
  803e7f:	48 b8 58 1d 80 00 00 	movabs $0x801d58,%rax
  803e86:	00 00 00 
  803e89:	ff d0                	callq  *%rax
  803e8b:	c9                   	leaveq 
  803e8c:	c3                   	retq   

0000000000803e8d <wait>:
  803e8d:	55                   	push   %rbp
  803e8e:	48 89 e5             	mov    %rsp,%rbp
  803e91:	48 83 ec 20          	sub    $0x20,%rsp
  803e95:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803e98:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803e9c:	75 35                	jne    803ed3 <wait+0x46>
  803e9e:	48 b9 95 4d 80 00 00 	movabs $0x804d95,%rcx
  803ea5:	00 00 00 
  803ea8:	48 ba a0 4d 80 00 00 	movabs $0x804da0,%rdx
  803eaf:	00 00 00 
  803eb2:	be 0a 00 00 00       	mov    $0xa,%esi
  803eb7:	48 bf b5 4d 80 00 00 	movabs $0x804db5,%rdi
  803ebe:	00 00 00 
  803ec1:	b8 00 00 00 00       	mov    $0x0,%eax
  803ec6:	49 b8 d5 41 80 00 00 	movabs $0x8041d5,%r8
  803ecd:	00 00 00 
  803ed0:	41 ff d0             	callq  *%r8
  803ed3:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803ed6:	25 ff 03 00 00       	and    $0x3ff,%eax
  803edb:	48 98                	cltq   
  803edd:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  803ee4:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  803eeb:	00 00 00 
  803eee:	48 01 d0             	add    %rdx,%rax
  803ef1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  803ef5:	eb 0c                	jmp    803f03 <wait+0x76>
  803ef7:	48 b8 6f 1c 80 00 00 	movabs $0x801c6f,%rax
  803efe:	00 00 00 
  803f01:	ff d0                	callq  *%rax
  803f03:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f07:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803f0d:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  803f10:	75 0e                	jne    803f20 <wait+0x93>
  803f12:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f16:	8b 80 d4 00 00 00    	mov    0xd4(%rax),%eax
  803f1c:	85 c0                	test   %eax,%eax
  803f1e:	75 d7                	jne    803ef7 <wait+0x6a>
  803f20:	c9                   	leaveq 
  803f21:	c3                   	retq   

0000000000803f22 <cputchar>:
  803f22:	55                   	push   %rbp
  803f23:	48 89 e5             	mov    %rsp,%rbp
  803f26:	48 83 ec 20          	sub    $0x20,%rsp
  803f2a:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803f2d:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803f30:	88 45 ff             	mov    %al,-0x1(%rbp)
  803f33:	48 8d 45 ff          	lea    -0x1(%rbp),%rax
  803f37:	be 01 00 00 00       	mov    $0x1,%esi
  803f3c:	48 89 c7             	mov    %rax,%rdi
  803f3f:	48 b8 65 1b 80 00 00 	movabs $0x801b65,%rax
  803f46:	00 00 00 
  803f49:	ff d0                	callq  *%rax
  803f4b:	c9                   	leaveq 
  803f4c:	c3                   	retq   

0000000000803f4d <getchar>:
  803f4d:	55                   	push   %rbp
  803f4e:	48 89 e5             	mov    %rsp,%rbp
  803f51:	48 83 ec 10          	sub    $0x10,%rsp
  803f55:	48 8d 45 fb          	lea    -0x5(%rbp),%rax
  803f59:	ba 01 00 00 00       	mov    $0x1,%edx
  803f5e:	48 89 c6             	mov    %rax,%rsi
  803f61:	bf 00 00 00 00       	mov    $0x0,%edi
  803f66:	48 b8 a5 25 80 00 00 	movabs $0x8025a5,%rax
  803f6d:	00 00 00 
  803f70:	ff d0                	callq  *%rax
  803f72:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803f75:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803f79:	79 05                	jns    803f80 <getchar+0x33>
  803f7b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803f7e:	eb 14                	jmp    803f94 <getchar+0x47>
  803f80:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803f84:	7f 07                	jg     803f8d <getchar+0x40>
  803f86:	b8 f7 ff ff ff       	mov    $0xfffffff7,%eax
  803f8b:	eb 07                	jmp    803f94 <getchar+0x47>
  803f8d:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  803f91:	0f b6 c0             	movzbl %al,%eax
  803f94:	c9                   	leaveq 
  803f95:	c3                   	retq   

0000000000803f96 <iscons>:
  803f96:	55                   	push   %rbp
  803f97:	48 89 e5             	mov    %rsp,%rbp
  803f9a:	48 83 ec 20          	sub    $0x20,%rsp
  803f9e:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803fa1:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  803fa5:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803fa8:	48 89 d6             	mov    %rdx,%rsi
  803fab:	89 c7                	mov    %eax,%edi
  803fad:	48 b8 73 21 80 00 00 	movabs $0x802173,%rax
  803fb4:	00 00 00 
  803fb7:	ff d0                	callq  *%rax
  803fb9:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803fbc:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803fc0:	79 05                	jns    803fc7 <iscons+0x31>
  803fc2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803fc5:	eb 1a                	jmp    803fe1 <iscons+0x4b>
  803fc7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803fcb:	8b 10                	mov    (%rax),%edx
  803fcd:	48 b8 20 61 80 00 00 	movabs $0x806120,%rax
  803fd4:	00 00 00 
  803fd7:	8b 00                	mov    (%rax),%eax
  803fd9:	39 c2                	cmp    %eax,%edx
  803fdb:	0f 94 c0             	sete   %al
  803fde:	0f b6 c0             	movzbl %al,%eax
  803fe1:	c9                   	leaveq 
  803fe2:	c3                   	retq   

0000000000803fe3 <opencons>:
  803fe3:	55                   	push   %rbp
  803fe4:	48 89 e5             	mov    %rsp,%rbp
  803fe7:	48 83 ec 10          	sub    $0x10,%rsp
  803feb:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  803fef:	48 89 c7             	mov    %rax,%rdi
  803ff2:	48 b8 db 20 80 00 00 	movabs $0x8020db,%rax
  803ff9:	00 00 00 
  803ffc:	ff d0                	callq  *%rax
  803ffe:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804001:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804005:	79 05                	jns    80400c <opencons+0x29>
  804007:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80400a:	eb 5b                	jmp    804067 <opencons+0x84>
  80400c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804010:	ba 07 04 00 00       	mov    $0x407,%edx
  804015:	48 89 c6             	mov    %rax,%rsi
  804018:	bf 00 00 00 00       	mov    $0x0,%edi
  80401d:	48 b8 ad 1c 80 00 00 	movabs $0x801cad,%rax
  804024:	00 00 00 
  804027:	ff d0                	callq  *%rax
  804029:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80402c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804030:	79 05                	jns    804037 <opencons+0x54>
  804032:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804035:	eb 30                	jmp    804067 <opencons+0x84>
  804037:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80403b:	48 ba 20 61 80 00 00 	movabs $0x806120,%rdx
  804042:	00 00 00 
  804045:	8b 12                	mov    (%rdx),%edx
  804047:	89 10                	mov    %edx,(%rax)
  804049:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80404d:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  804054:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804058:	48 89 c7             	mov    %rax,%rdi
  80405b:	48 b8 8d 20 80 00 00 	movabs $0x80208d,%rax
  804062:	00 00 00 
  804065:	ff d0                	callq  *%rax
  804067:	c9                   	leaveq 
  804068:	c3                   	retq   

0000000000804069 <devcons_read>:
  804069:	55                   	push   %rbp
  80406a:	48 89 e5             	mov    %rsp,%rbp
  80406d:	48 83 ec 30          	sub    $0x30,%rsp
  804071:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  804075:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  804079:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80407d:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  804082:	75 07                	jne    80408b <devcons_read+0x22>
  804084:	b8 00 00 00 00       	mov    $0x0,%eax
  804089:	eb 4b                	jmp    8040d6 <devcons_read+0x6d>
  80408b:	eb 0c                	jmp    804099 <devcons_read+0x30>
  80408d:	48 b8 6f 1c 80 00 00 	movabs $0x801c6f,%rax
  804094:	00 00 00 
  804097:	ff d0                	callq  *%rax
  804099:	48 b8 af 1b 80 00 00 	movabs $0x801baf,%rax
  8040a0:	00 00 00 
  8040a3:	ff d0                	callq  *%rax
  8040a5:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8040a8:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8040ac:	74 df                	je     80408d <devcons_read+0x24>
  8040ae:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8040b2:	79 05                	jns    8040b9 <devcons_read+0x50>
  8040b4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8040b7:	eb 1d                	jmp    8040d6 <devcons_read+0x6d>
  8040b9:	83 7d fc 04          	cmpl   $0x4,-0x4(%rbp)
  8040bd:	75 07                	jne    8040c6 <devcons_read+0x5d>
  8040bf:	b8 00 00 00 00       	mov    $0x0,%eax
  8040c4:	eb 10                	jmp    8040d6 <devcons_read+0x6d>
  8040c6:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8040c9:	89 c2                	mov    %eax,%edx
  8040cb:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8040cf:	88 10                	mov    %dl,(%rax)
  8040d1:	b8 01 00 00 00       	mov    $0x1,%eax
  8040d6:	c9                   	leaveq 
  8040d7:	c3                   	retq   

00000000008040d8 <devcons_write>:
  8040d8:	55                   	push   %rbp
  8040d9:	48 89 e5             	mov    %rsp,%rbp
  8040dc:	48 81 ec b0 00 00 00 	sub    $0xb0,%rsp
  8040e3:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  8040ea:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  8040f1:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  8040f8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8040ff:	eb 76                	jmp    804177 <devcons_write+0x9f>
  804101:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  804108:	89 c2                	mov    %eax,%edx
  80410a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80410d:	29 c2                	sub    %eax,%edx
  80410f:	89 d0                	mov    %edx,%eax
  804111:	89 45 f8             	mov    %eax,-0x8(%rbp)
  804114:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804117:	83 f8 7f             	cmp    $0x7f,%eax
  80411a:	76 07                	jbe    804123 <devcons_write+0x4b>
  80411c:	c7 45 f8 7f 00 00 00 	movl   $0x7f,-0x8(%rbp)
  804123:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804126:	48 63 d0             	movslq %eax,%rdx
  804129:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80412c:	48 63 c8             	movslq %eax,%rcx
  80412f:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
  804136:	48 01 c1             	add    %rax,%rcx
  804139:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  804140:	48 89 ce             	mov    %rcx,%rsi
  804143:	48 89 c7             	mov    %rax,%rdi
  804146:	48 b8 a2 16 80 00 00 	movabs $0x8016a2,%rax
  80414d:	00 00 00 
  804150:	ff d0                	callq  *%rax
  804152:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804155:	48 63 d0             	movslq %eax,%rdx
  804158:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  80415f:	48 89 d6             	mov    %rdx,%rsi
  804162:	48 89 c7             	mov    %rax,%rdi
  804165:	48 b8 65 1b 80 00 00 	movabs $0x801b65,%rax
  80416c:	00 00 00 
  80416f:	ff d0                	callq  *%rax
  804171:	8b 45 f8             	mov    -0x8(%rbp),%eax
  804174:	01 45 fc             	add    %eax,-0x4(%rbp)
  804177:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80417a:	48 98                	cltq   
  80417c:	48 3b 85 58 ff ff ff 	cmp    -0xa8(%rbp),%rax
  804183:	0f 82 78 ff ff ff    	jb     804101 <devcons_write+0x29>
  804189:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80418c:	c9                   	leaveq 
  80418d:	c3                   	retq   

000000000080418e <devcons_close>:
  80418e:	55                   	push   %rbp
  80418f:	48 89 e5             	mov    %rsp,%rbp
  804192:	48 83 ec 08          	sub    $0x8,%rsp
  804196:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80419a:	b8 00 00 00 00       	mov    $0x0,%eax
  80419f:	c9                   	leaveq 
  8041a0:	c3                   	retq   

00000000008041a1 <devcons_stat>:
  8041a1:	55                   	push   %rbp
  8041a2:	48 89 e5             	mov    %rsp,%rbp
  8041a5:	48 83 ec 10          	sub    $0x10,%rsp
  8041a9:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8041ad:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8041b1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8041b5:	48 be c8 4d 80 00 00 	movabs $0x804dc8,%rsi
  8041bc:	00 00 00 
  8041bf:	48 89 c7             	mov    %rax,%rdi
  8041c2:	48 b8 7e 13 80 00 00 	movabs $0x80137e,%rax
  8041c9:	00 00 00 
  8041cc:	ff d0                	callq  *%rax
  8041ce:	b8 00 00 00 00       	mov    $0x0,%eax
  8041d3:	c9                   	leaveq 
  8041d4:	c3                   	retq   

00000000008041d5 <_panic>:
  8041d5:	55                   	push   %rbp
  8041d6:	48 89 e5             	mov    %rsp,%rbp
  8041d9:	53                   	push   %rbx
  8041da:	48 81 ec f8 00 00 00 	sub    $0xf8,%rsp
  8041e1:	48 89 bd 18 ff ff ff 	mov    %rdi,-0xe8(%rbp)
  8041e8:	89 b5 14 ff ff ff    	mov    %esi,-0xec(%rbp)
  8041ee:	48 89 8d 58 ff ff ff 	mov    %rcx,-0xa8(%rbp)
  8041f5:	4c 89 85 60 ff ff ff 	mov    %r8,-0xa0(%rbp)
  8041fc:	4c 89 8d 68 ff ff ff 	mov    %r9,-0x98(%rbp)
  804203:	84 c0                	test   %al,%al
  804205:	74 23                	je     80422a <_panic+0x55>
  804207:	0f 29 85 70 ff ff ff 	movaps %xmm0,-0x90(%rbp)
  80420e:	0f 29 4d 80          	movaps %xmm1,-0x80(%rbp)
  804212:	0f 29 55 90          	movaps %xmm2,-0x70(%rbp)
  804216:	0f 29 5d a0          	movaps %xmm3,-0x60(%rbp)
  80421a:	0f 29 65 b0          	movaps %xmm4,-0x50(%rbp)
  80421e:	0f 29 6d c0          	movaps %xmm5,-0x40(%rbp)
  804222:	0f 29 75 d0          	movaps %xmm6,-0x30(%rbp)
  804226:	0f 29 7d e0          	movaps %xmm7,-0x20(%rbp)
  80422a:	48 89 95 08 ff ff ff 	mov    %rdx,-0xf8(%rbp)
  804231:	c7 85 28 ff ff ff 18 	movl   $0x18,-0xd8(%rbp)
  804238:	00 00 00 
  80423b:	c7 85 2c ff ff ff 30 	movl   $0x30,-0xd4(%rbp)
  804242:	00 00 00 
  804245:	48 8d 45 10          	lea    0x10(%rbp),%rax
  804249:	48 89 85 30 ff ff ff 	mov    %rax,-0xd0(%rbp)
  804250:	48 8d 85 40 ff ff ff 	lea    -0xc0(%rbp),%rax
  804257:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  80425e:	48 b8 00 60 80 00 00 	movabs $0x806000,%rax
  804265:	00 00 00 
  804268:	48 8b 18             	mov    (%rax),%rbx
  80426b:	48 b8 31 1c 80 00 00 	movabs $0x801c31,%rax
  804272:	00 00 00 
  804275:	ff d0                	callq  *%rax
  804277:	8b 8d 14 ff ff ff    	mov    -0xec(%rbp),%ecx
  80427d:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  804284:	41 89 c8             	mov    %ecx,%r8d
  804287:	48 89 d1             	mov    %rdx,%rcx
  80428a:	48 89 da             	mov    %rbx,%rdx
  80428d:	89 c6                	mov    %eax,%esi
  80428f:	48 bf d0 4d 80 00 00 	movabs $0x804dd0,%rdi
  804296:	00 00 00 
  804299:	b8 00 00 00 00       	mov    $0x0,%eax
  80429e:	49 b9 c9 07 80 00 00 	movabs $0x8007c9,%r9
  8042a5:	00 00 00 
  8042a8:	41 ff d1             	callq  *%r9
  8042ab:	48 8d 95 28 ff ff ff 	lea    -0xd8(%rbp),%rdx
  8042b2:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8042b9:	48 89 d6             	mov    %rdx,%rsi
  8042bc:	48 89 c7             	mov    %rax,%rdi
  8042bf:	48 b8 1d 07 80 00 00 	movabs $0x80071d,%rax
  8042c6:	00 00 00 
  8042c9:	ff d0                	callq  *%rax
  8042cb:	48 bf f3 4d 80 00 00 	movabs $0x804df3,%rdi
  8042d2:	00 00 00 
  8042d5:	b8 00 00 00 00       	mov    $0x0,%eax
  8042da:	48 ba c9 07 80 00 00 	movabs $0x8007c9,%rdx
  8042e1:	00 00 00 
  8042e4:	ff d2                	callq  *%rdx
  8042e6:	cc                   	int3   
  8042e7:	eb fd                	jmp    8042e6 <_panic+0x111>

00000000008042e9 <ipc_recv>:
  8042e9:	55                   	push   %rbp
  8042ea:	48 89 e5             	mov    %rsp,%rbp
  8042ed:	48 83 ec 30          	sub    $0x30,%rsp
  8042f1:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8042f5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8042f9:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8042fd:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  804302:	75 0e                	jne    804312 <ipc_recv+0x29>
  804304:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  80430b:	00 00 00 
  80430e:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  804312:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  804316:	48 89 c7             	mov    %rax,%rdi
  804319:	48 b8 d6 1e 80 00 00 	movabs $0x801ed6,%rax
  804320:	00 00 00 
  804323:	ff d0                	callq  *%rax
  804325:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804328:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80432c:	79 27                	jns    804355 <ipc_recv+0x6c>
  80432e:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  804333:	74 0a                	je     80433f <ipc_recv+0x56>
  804335:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  804339:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  80433f:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  804344:	74 0a                	je     804350 <ipc_recv+0x67>
  804346:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80434a:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  804350:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804353:	eb 53                	jmp    8043a8 <ipc_recv+0xbf>
  804355:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80435a:	74 19                	je     804375 <ipc_recv+0x8c>
  80435c:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  804363:	00 00 00 
  804366:	48 8b 00             	mov    (%rax),%rax
  804369:	8b 90 0c 01 00 00    	mov    0x10c(%rax),%edx
  80436f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  804373:	89 10                	mov    %edx,(%rax)
  804375:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  80437a:	74 19                	je     804395 <ipc_recv+0xac>
  80437c:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  804383:	00 00 00 
  804386:	48 8b 00             	mov    (%rax),%rax
  804389:	8b 90 10 01 00 00    	mov    0x110(%rax),%edx
  80438f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  804393:	89 10                	mov    %edx,(%rax)
  804395:	48 b8 08 70 80 00 00 	movabs $0x807008,%rax
  80439c:	00 00 00 
  80439f:	48 8b 00             	mov    (%rax),%rax
  8043a2:	8b 80 08 01 00 00    	mov    0x108(%rax),%eax
  8043a8:	c9                   	leaveq 
  8043a9:	c3                   	retq   

00000000008043aa <ipc_send>:
  8043aa:	55                   	push   %rbp
  8043ab:	48 89 e5             	mov    %rsp,%rbp
  8043ae:	48 83 ec 30          	sub    $0x30,%rsp
  8043b2:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8043b5:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8043b8:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
  8043bc:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  8043bf:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8043c4:	75 10                	jne    8043d6 <ipc_send+0x2c>
  8043c6:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  8043cd:	00 00 00 
  8043d0:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8043d4:	eb 0e                	jmp    8043e4 <ipc_send+0x3a>
  8043d6:	eb 0c                	jmp    8043e4 <ipc_send+0x3a>
  8043d8:	48 b8 6f 1c 80 00 00 	movabs $0x801c6f,%rax
  8043df:	00 00 00 
  8043e2:	ff d0                	callq  *%rax
  8043e4:	8b 75 e8             	mov    -0x18(%rbp),%esi
  8043e7:	8b 4d dc             	mov    -0x24(%rbp),%ecx
  8043ea:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8043ee:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8043f1:	89 c7                	mov    %eax,%edi
  8043f3:	48 b8 81 1e 80 00 00 	movabs $0x801e81,%rax
  8043fa:	00 00 00 
  8043fd:	ff d0                	callq  *%rax
  8043ff:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804402:	83 7d fc f8          	cmpl   $0xfffffff8,-0x4(%rbp)
  804406:	74 d0                	je     8043d8 <ipc_send+0x2e>
  804408:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80440c:	79 30                	jns    80443e <ipc_send+0x94>
  80440e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804411:	89 c1                	mov    %eax,%ecx
  804413:	48 ba f8 4d 80 00 00 	movabs $0x804df8,%rdx
  80441a:	00 00 00 
  80441d:	be 44 00 00 00       	mov    $0x44,%esi
  804422:	48 bf 0e 4e 80 00 00 	movabs $0x804e0e,%rdi
  804429:	00 00 00 
  80442c:	b8 00 00 00 00       	mov    $0x0,%eax
  804431:	49 b8 d5 41 80 00 00 	movabs $0x8041d5,%r8
  804438:	00 00 00 
  80443b:	41 ff d0             	callq  *%r8
  80443e:	c9                   	leaveq 
  80443f:	c3                   	retq   

0000000000804440 <ipc_host_recv>:
  804440:	55                   	push   %rbp
  804441:	48 89 e5             	mov    %rsp,%rbp
  804444:	48 83 ec 10          	sub    $0x10,%rsp
  804448:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80444c:	48 ba 20 4e 80 00 00 	movabs $0x804e20,%rdx
  804453:	00 00 00 
  804456:	be 4e 00 00 00       	mov    $0x4e,%esi
  80445b:	48 bf 0e 4e 80 00 00 	movabs $0x804e0e,%rdi
  804462:	00 00 00 
  804465:	b8 00 00 00 00       	mov    $0x0,%eax
  80446a:	48 b9 d5 41 80 00 00 	movabs $0x8041d5,%rcx
  804471:	00 00 00 
  804474:	ff d1                	callq  *%rcx

0000000000804476 <ipc_host_send>:
  804476:	55                   	push   %rbp
  804477:	48 89 e5             	mov    %rsp,%rbp
  80447a:	48 83 ec 20          	sub    $0x20,%rsp
  80447e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  804481:	89 75 f8             	mov    %esi,-0x8(%rbp)
  804484:	48 89 55 f0          	mov    %rdx,-0x10(%rbp)
  804488:	89 4d ec             	mov    %ecx,-0x14(%rbp)
  80448b:	48 ba 40 4e 80 00 00 	movabs $0x804e40,%rdx
  804492:	00 00 00 
  804495:	be 67 00 00 00       	mov    $0x67,%esi
  80449a:	48 bf 0e 4e 80 00 00 	movabs $0x804e0e,%rdi
  8044a1:	00 00 00 
  8044a4:	b8 00 00 00 00       	mov    $0x0,%eax
  8044a9:	48 b9 d5 41 80 00 00 	movabs $0x8041d5,%rcx
  8044b0:	00 00 00 
  8044b3:	ff d1                	callq  *%rcx

00000000008044b5 <ipc_find_env>:
  8044b5:	55                   	push   %rbp
  8044b6:	48 89 e5             	mov    %rsp,%rbp
  8044b9:	48 83 ec 14          	sub    $0x14,%rsp
  8044bd:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8044c0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8044c7:	eb 4e                	jmp    804517 <ipc_find_env+0x62>
  8044c9:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  8044d0:	00 00 00 
  8044d3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8044d6:	48 98                	cltq   
  8044d8:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  8044df:	48 01 d0             	add    %rdx,%rax
  8044e2:	48 05 d0 00 00 00    	add    $0xd0,%rax
  8044e8:	8b 00                	mov    (%rax),%eax
  8044ea:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  8044ed:	75 24                	jne    804513 <ipc_find_env+0x5e>
  8044ef:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  8044f6:	00 00 00 
  8044f9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8044fc:	48 98                	cltq   
  8044fe:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  804505:	48 01 d0             	add    %rdx,%rax
  804508:	48 05 c0 00 00 00    	add    $0xc0,%rax
  80450e:	8b 40 08             	mov    0x8(%rax),%eax
  804511:	eb 12                	jmp    804525 <ipc_find_env+0x70>
  804513:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  804517:	81 7d fc ff 03 00 00 	cmpl   $0x3ff,-0x4(%rbp)
  80451e:	7e a9                	jle    8044c9 <ipc_find_env+0x14>
  804520:	b8 00 00 00 00       	mov    $0x0,%eax
  804525:	c9                   	leaveq 
  804526:	c3                   	retq   

0000000000804527 <pageref>:
  804527:	55                   	push   %rbp
  804528:	48 89 e5             	mov    %rsp,%rbp
  80452b:	48 83 ec 18          	sub    $0x18,%rsp
  80452f:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  804533:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  804537:	48 c1 e8 15          	shr    $0x15,%rax
  80453b:	48 89 c2             	mov    %rax,%rdx
  80453e:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  804545:	01 00 00 
  804548:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80454c:	83 e0 01             	and    $0x1,%eax
  80454f:	48 85 c0             	test   %rax,%rax
  804552:	75 07                	jne    80455b <pageref+0x34>
  804554:	b8 00 00 00 00       	mov    $0x0,%eax
  804559:	eb 53                	jmp    8045ae <pageref+0x87>
  80455b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80455f:	48 c1 e8 0c          	shr    $0xc,%rax
  804563:	48 89 c2             	mov    %rax,%rdx
  804566:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  80456d:	01 00 00 
  804570:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  804574:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  804578:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80457c:	83 e0 01             	and    $0x1,%eax
  80457f:	48 85 c0             	test   %rax,%rax
  804582:	75 07                	jne    80458b <pageref+0x64>
  804584:	b8 00 00 00 00       	mov    $0x0,%eax
  804589:	eb 23                	jmp    8045ae <pageref+0x87>
  80458b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80458f:	48 c1 e8 0c          	shr    $0xc,%rax
  804593:	48 89 c2             	mov    %rax,%rdx
  804596:	48 b8 00 00 a0 00 80 	movabs $0x8000a00000,%rax
  80459d:	00 00 00 
  8045a0:	48 c1 e2 04          	shl    $0x4,%rdx
  8045a4:	48 01 d0             	add    %rdx,%rax
  8045a7:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  8045ab:	0f b7 c0             	movzwl %ax,%eax
  8045ae:	c9                   	leaveq 
  8045af:	c3                   	retq   
