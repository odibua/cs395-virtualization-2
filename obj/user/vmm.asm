
obj/user/vmm:     file format elf64-x86-64


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
  80003c:	e8 02 07 00 00       	callq  800743 <libmain>
1:	jmp 1b
  800041:	eb fe                	jmp    800041 <args_exist+0xe>

0000000000800043 <map_in_guest>:
//
// Hint: Call sys_ept_map() for mapping page.
static int
map_in_guest(envid_t guest, uintptr_t gpa, size_t memsz,
			 int fd, size_t filesz, off_t fileoffset)
{
  800043:	55                   	push   %rbp
  800044:	48 89 e5             	mov    %rsp,%rbp
  800047:	48 83 ec 50          	sub    $0x50,%rsp
  80004b:	89 7d dc             	mov    %edi,-0x24(%rbp)
  80004e:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  800052:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  800056:	89 4d d8             	mov    %ecx,-0x28(%rbp)
  800059:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  80005d:	44 89 4d bc          	mov    %r9d,-0x44(%rbp)
	/* Your code here */
	int index = 0;
  800061:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
	int statusFlag = -1;
  800068:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,-0x8(%rbp)

	//Round down to the nearest multiple of PGSIZE starting at guest's phy addr
	if (PGOFF(gpa) != 0)
  80006f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800073:	25 ff 0f 00 00       	and    $0xfff,%eax
  800078:	48 85 c0             	test   %rax,%rax
  80007b:	74 08                	je     800085 <map_in_guest+0x42>
		ROUNDDOWN(gpa, PGSIZE);
  80007d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800081:	48 89 45 f0          	mov    %rax,-0x10(%rbp)

	for (index = 0; index < memsz; index += PGSIZE)
  800085:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80008c:	e9 81 02 00 00       	jmpq   800312 <map_in_guest+0x2cf>
	{
		if (index < filesz)
  800091:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800094:	48 98                	cltq   
  800096:	48 3b 45 c0          	cmp    -0x40(%rbp),%rax
  80009a:	0f 83 77 01 00 00    	jae    800217 <map_in_guest+0x1d4>
		{
			/* alloc a page in the env,temp map to use, permission flags as arg 3
			PTE_P- is present check */
			statusFlag = sys_page_alloc(thisenv->env_id, UTEMP, PTE_P | PTE_U | PTE_W);
  8000a0:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  8000a7:	00 00 00 
  8000aa:	48 8b 00             	mov    (%rax),%rax
  8000ad:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8000b3:	ba 07 00 00 00       	mov    $0x7,%edx
  8000b8:	be 00 00 40 00       	mov    $0x400000,%esi
  8000bd:	89 c7                	mov    %eax,%edi
  8000bf:	48 b8 06 1f 80 00 00 	movabs $0x801f06,%rax
  8000c6:	00 00 00 
  8000c9:	ff d0                	callq  *%rax
  8000cb:	89 45 f8             	mov    %eax,-0x8(%rbp)

			if (statusFlag < 0)
  8000ce:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8000d2:	79 08                	jns    8000dc <map_in_guest+0x99>
				return statusFlag;
  8000d4:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8000d7:	e9 4a 02 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			// from offset loc, move page by page, index increments by pagesize
			statusFlag = seek(fd, fileoffset + index);
  8000dc:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8000df:	8b 55 bc             	mov    -0x44(%rbp),%edx
  8000e2:	01 c2                	add    %eax,%edx
  8000e4:	8b 45 d8             	mov    -0x28(%rbp),%eax
  8000e7:	89 d6                	mov    %edx,%esi
  8000e9:	89 c7                	mov    %eax,%edi
  8000eb:	48 b8 1a 2b 80 00 00 	movabs $0x802b1a,%rax
  8000f2:	00 00 00 
  8000f5:	ff d0                	callq  *%rax
  8000f7:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0)
  8000fa:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8000fe:	79 08                	jns    800108 <map_in_guest+0xc5>
				return statusFlag;
  800100:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800103:	e9 1e 02 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			// read opened file
			statusFlag = readn(fd, UTEMP, MIN(PGSIZE, filesz - index));
  800108:	c7 45 ec 00 10 00 00 	movl   $0x1000,-0x14(%rbp)
  80010f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800112:	48 98                	cltq   
  800114:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800118:	48 29 c2             	sub    %rax,%rdx
  80011b:	48 89 d0             	mov    %rdx,%rax
  80011e:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  800122:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800125:	48 63 d0             	movslq %eax,%rdx
  800128:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80012c:	48 39 c2             	cmp    %rax,%rdx
  80012f:	48 0f 47 d0          	cmova  %rax,%rdx
  800133:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800136:	be 00 00 40 00       	mov    $0x400000,%esi
  80013b:	89 c7                	mov    %eax,%edi
  80013d:	48 b8 d1 29 80 00 00 	movabs $0x8029d1,%rax
  800144:	00 00 00 
  800147:	ff d0                	callq  *%rax
  800149:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0)
  80014c:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800150:	79 08                	jns    80015a <map_in_guest+0x117>
				return statusFlag;
  800152:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800155:	e9 cc 01 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			// page to be mapped for guest
			statusFlag = sys_ept_map(thisenv->env_id, (void *)UTEMP, guest, (void *)(gpa + index), __EPTE_FULL);
  80015a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80015d:	48 63 d0             	movslq %eax,%rdx
  800160:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  800164:	48 01 d0             	add    %rdx,%rax
  800167:	48 89 c1             	mov    %rax,%rcx
  80016a:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  800171:	00 00 00 
  800174:	48 8b 00             	mov    (%rax),%rax
  800177:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80017d:	8b 55 dc             	mov    -0x24(%rbp),%edx
  800180:	41 b8 07 00 00 00    	mov    $0x7,%r8d
  800186:	be 00 00 40 00       	mov    $0x400000,%esi
  80018b:	89 c7                	mov    %eax,%edi
  80018d:	48 b8 41 22 80 00 00 	movabs $0x802241,%rax
  800194:	00 00 00 
  800197:	ff d0                	callq  *%rax
  800199:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0){
  80019c:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8001a0:	79 4a                	jns    8001ec <map_in_guest+0x1a9>
				cprintf("Page map failure (If block): %e", statusFlag);
  8001a2:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8001a5:	89 c6                	mov    %eax,%esi
  8001a7:	48 bf 80 47 80 00 00 	movabs $0x804780,%rdi
  8001ae:	00 00 00 
  8001b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8001b6:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  8001bd:	00 00 00 
  8001c0:	ff d2                	callq  *%rdx
				panic("Page map failure - If block");
  8001c2:	48 ba a0 47 80 00 00 	movabs $0x8047a0,%rdx
  8001c9:	00 00 00 
  8001cc:	be 38 00 00 00       	mov    $0x38,%esi
  8001d1:	48 bf bc 47 80 00 00 	movabs $0x8047bc,%rdi
  8001d8:	00 00 00 
  8001db:	b8 00 00 00 00       	mov    $0x0,%eax
  8001e0:	48 b9 e9 07 80 00 00 	movabs $0x8007e9,%rcx
  8001e7:	00 00 00 
  8001ea:	ff d1                	callq  *%rcx
			}
			// Unmap - not req anymore
			sys_page_unmap(thisenv->env_id, UTEMP);
  8001ec:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  8001f3:	00 00 00 
  8001f6:	48 8b 00             	mov    (%rax),%rax
  8001f9:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8001ff:	be 00 00 40 00       	mov    $0x400000,%esi
  800204:	89 c7                	mov    %eax,%edi
  800206:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  80020d:	00 00 00 
  800210:	ff d0                	callq  *%rax
  800212:	e9 f4 00 00 00       	jmpq   80030b <map_in_guest+0x2c8>
		}

		else
		{
			statusFlag = sys_page_alloc(thisenv->env_id, (void *)UTEMP, __EPTE_FULL);
  800217:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  80021e:	00 00 00 
  800221:	48 8b 00             	mov    (%rax),%rax
  800224:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80022a:	ba 07 00 00 00       	mov    $0x7,%edx
  80022f:	be 00 00 40 00       	mov    $0x400000,%esi
  800234:	89 c7                	mov    %eax,%edi
  800236:	48 b8 06 1f 80 00 00 	movabs $0x801f06,%rax
  80023d:	00 00 00 
  800240:	ff d0                	callq  *%rax
  800242:	89 45 f8             	mov    %eax,-0x8(%rbp)
			if (statusFlag < 0)
  800245:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800249:	79 08                	jns    800253 <map_in_guest+0x210>
				return statusFlag;
  80024b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80024e:	e9 d3 00 00 00       	jmpq   800326 <map_in_guest+0x2e3>

			statusFlag = sys_ept_map(thisenv->env_id, UTEMP, guest, (void *)(gpa + index), __EPTE_FULL);
  800253:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800256:	48 63 d0             	movslq %eax,%rdx
  800259:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80025d:	48 01 d0             	add    %rdx,%rax
  800260:	48 89 c1             	mov    %rax,%rcx
  800263:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  80026a:	00 00 00 
  80026d:	48 8b 00             	mov    (%rax),%rax
  800270:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  800276:	8b 55 dc             	mov    -0x24(%rbp),%edx
  800279:	41 b8 07 00 00 00    	mov    $0x7,%r8d
  80027f:	be 00 00 40 00       	mov    $0x400000,%esi
  800284:	89 c7                	mov    %eax,%edi
  800286:	48 b8 41 22 80 00 00 	movabs $0x802241,%rax
  80028d:	00 00 00 
  800290:	ff d0                	callq  *%rax
  800292:	89 45 f8             	mov    %eax,-0x8(%rbp)

			if (statusFlag < 0){
  800295:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  800299:	79 4a                	jns    8002e5 <map_in_guest+0x2a2>
				cprintf("Page map failure (else block): %e", statusFlag);
  80029b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80029e:	89 c6                	mov    %eax,%esi
  8002a0:	48 bf c8 47 80 00 00 	movabs $0x8047c8,%rdi
  8002a7:	00 00 00 
  8002aa:	b8 00 00 00 00       	mov    $0x0,%eax
  8002af:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  8002b6:	00 00 00 
  8002b9:	ff d2                	callq  *%rdx
				panic("Page map failure - else block");
  8002bb:	48 ba ea 47 80 00 00 	movabs $0x8047ea,%rdx
  8002c2:	00 00 00 
  8002c5:	be 48 00 00 00       	mov    $0x48,%esi
  8002ca:	48 bf bc 47 80 00 00 	movabs $0x8047bc,%rdi
  8002d1:	00 00 00 
  8002d4:	b8 00 00 00 00       	mov    $0x0,%eax
  8002d9:	48 b9 e9 07 80 00 00 	movabs $0x8007e9,%rcx
  8002e0:	00 00 00 
  8002e3:	ff d1                	callq  *%rcx
			}
			//unmap
			sys_page_unmap(thisenv->env_id, UTEMP);
  8002e5:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  8002ec:	00 00 00 
  8002ef:	48 8b 00             	mov    (%rax),%rax
  8002f2:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8002f8:	be 00 00 40 00       	mov    $0x400000,%esi
  8002fd:	89 c7                	mov    %eax,%edi
  8002ff:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  800306:	00 00 00 
  800309:	ff d0                	callq  *%rax

	//Round down to the nearest multiple of PGSIZE starting at guest's phy addr
	if (PGOFF(gpa) != 0)
		ROUNDDOWN(gpa, PGSIZE);

	for (index = 0; index < memsz; index += PGSIZE)
  80030b:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%rbp)
  800312:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800315:	48 98                	cltq   
  800317:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  80031b:	0f 82 70 fd ff ff    	jb     800091 <map_in_guest+0x4e>
			}
			//unmap
			sys_page_unmap(thisenv->env_id, UTEMP);
		}
	}
	return 0; // success
  800321:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800326:	c9                   	leaveq 
  800327:	c3                   	retq   

0000000000800328 <copy_guest_kern_gpa>:
// Return 0 on success, <0 on error
//
// Hint: compare with ELF parsing in env.c, and use map_in_guest for each segment.
static int
copy_guest_kern_gpa(envid_t guest, char *fname)
{
  800328:	55                   	push   %rbp
  800329:	48 89 e5             	mov    %rsp,%rbp
  80032c:	48 81 ec 40 04 00 00 	sub    $0x440,%rsp
  800333:	89 bd cc fb ff ff    	mov    %edi,-0x434(%rbp)
  800339:	48 89 b5 c0 fb ff ff 	mov    %rsi,-0x440(%rbp)
	/* Your code here */

	int fileDesc = -1; 		//to be able to read
  800340:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%rbp)
	int mapStatus = -1;		
  800347:	c7 45 fc ff ff ff ff 	movl   $0xffffffff,-0x4(%rbp)
	char fileData[1024];	//how much to read into buffer	
	struct Elf *fileHeader;	//binary validation using this struct to be done
	size_t totalRead = 0;	//to error check, binary validation
  80034e:	48 c7 45 e0 00 00 00 	movq   $0x0,-0x20(%rbp)
  800355:	00 

	// open file in readonly mode
	fileDesc = open(fname, O_RDONLY);
  800356:	48 8b 85 c0 fb ff ff 	mov    -0x440(%rbp),%rax
  80035d:	be 00 00 00 00       	mov    $0x0,%esi
  800362:	48 89 c7             	mov    %rax,%rdi
  800365:	48 b8 d2 2d 80 00 00 	movabs $0x802dd2,%rax
  80036c:	00 00 00 
  80036f:	ff d0                	callq  *%rax
  800371:	89 45 ec             	mov    %eax,-0x14(%rbp)

	//error opening file
	if (fileDesc < 0)
  800374:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  800378:	79 0a                	jns    800384 <copy_guest_kern_gpa+0x5c>
		return -E_NOT_FOUND;
  80037a:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
  80037f:	e9 4a 01 00 00       	jmpq   8004ce <copy_guest_kern_gpa+0x1a6>

	//if opened, read into buffer
	totalRead = readn(fileDesc, fileData, sizeof(fileData));
  800384:	48 8d 8d d0 fb ff ff 	lea    -0x430(%rbp),%rcx
  80038b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80038e:	ba 00 04 00 00       	mov    $0x400,%edx
  800393:	48 89 ce             	mov    %rcx,%rsi
  800396:	89 c7                	mov    %eax,%edi
  800398:	48 b8 d1 29 80 00 00 	movabs $0x8029d1,%rax
  80039f:	00 00 00 
  8003a2:	ff d0                	callq  *%rax
  8003a4:	48 98                	cltq   
  8003a6:	48 89 45 e0          	mov    %rax,-0x20(%rbp)

	if (totalRead != sizeof(fileData))
  8003aa:	48 81 7d e0 00 04 00 	cmpq   $0x400,-0x20(%rbp)
  8003b1:	00 
  8003b2:	74 1b                	je     8003cf <copy_guest_kern_gpa+0xa7>
	{ // mismatch in size
		close(fileDesc);
  8003b4:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8003b7:	89 c7                	mov    %eax,%edi
  8003b9:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  8003c0:	00 00 00 
  8003c3:	ff d0                	callq  *%rax
		return -E_NOT_FOUND; // ret -12
  8003c5:	b8 f4 ff ff ff       	mov    $0xfffffff4,%eax
  8003ca:	e9 ff 00 00 00       	jmpq   8004ce <copy_guest_kern_gpa+0x1a6>
	}

	fileHeader = (struct Elf *)fileData;
  8003cf:	48 8d 85 d0 fb ff ff 	lea    -0x430(%rbp),%rax
  8003d6:	48 89 45 d8          	mov    %rax,-0x28(%rbp)

	/*recall his header typically starts with a sequence of four unique bytes that are 0x7F followed by 0x45,
	0x4c, and 0x46 which on ASCII translation yields the three letters E, L, and F. 
	ELF_MAGIC = 0x464C457FU : read LSB to MSB */

	if (fileHeader->e_magic != ELF_MAGIC)
  8003da:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8003de:	8b 00                	mov    (%rax),%eax
  8003e0:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  8003e5:	74 1b                	je     800402 <copy_guest_kern_gpa+0xda>
	{
		close(fileDesc);
  8003e7:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8003ea:	89 c7                	mov    %eax,%edi
  8003ec:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  8003f3:	00 00 00 
  8003f6:	ff d0                	callq  *%rax
		return -E_NOT_EXEC; // not a suitable binary ELF was not found in header
  8003f8:	b8 f1 ff ff ff       	mov    $0xfffffff1,%eax
  8003fd:	e9 cc 00 00 00       	jmpq   8004ce <copy_guest_kern_gpa+0x1a6>
	}

	struct Proghdr *prgHdr = (struct Proghdr *)(fileData + fileHeader->e_phoff); //add offset to data and move tp prgHdr 
  800402:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800406:	48 8b 40 20          	mov    0x20(%rax),%rax
  80040a:	48 8d 95 d0 fb ff ff 	lea    -0x430(%rbp),%rdx
  800411:	48 01 d0             	add    %rdx,%rax
  800414:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
	struct Proghdr *endPrgHdr = prgHdr + fileHeader->e_phnum; // add more to prghdr, 32 bit offset
  800418:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80041c:	0f b7 40 38          	movzwl 0x38(%rax),%eax
  800420:	0f b7 c0             	movzwl %ax,%eax
  800423:	48 c1 e0 03          	shl    $0x3,%rax
  800427:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  80042e:	00 
  80042f:	48 29 c2             	sub    %rax,%rdx
  800432:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800436:	48 01 d0             	add    %rdx,%rax
  800439:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
	
	//prgHdr is already initialized
	for (; prgHdr < endPrgHdr; prgHdr++)
  80043d:	eb 71                	jmp    8004b0 <copy_guest_kern_gpa+0x188>
		/*The ELF header gets allocated by means of the macros defined in elf.h file. The constant
		*ELF PROG LOAD is carrying the value 1. This is actually the value for p type field of the
		*Proghdr structure. The value of 1 in particular means that the segment type is PT LOAD
		*/

		if (prgHdr->p_type == ELF_PROG_LOAD)
  80043f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800443:	8b 00                	mov    (%rax),%eax
  800445:	83 f8 01             	cmp    $0x1,%eax
  800448:	75 61                	jne    8004ab <copy_guest_kern_gpa+0x183>
		{
			mapStatus = map_in_guest(guest, prgHdr->p_pa,
									 prgHdr->p_memsz, fileDesc,
									prgHdr->p_filesz, prgHdr->p_offset);
  80044a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80044e:	48 8b 40 08          	mov    0x8(%rax),%rax
		*Proghdr structure. The value of 1 in particular means that the segment type is PT LOAD
		*/

		if (prgHdr->p_type == ELF_PROG_LOAD)
		{
			mapStatus = map_in_guest(guest, prgHdr->p_pa,
  800452:	41 89 c0             	mov    %eax,%r8d
  800455:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800459:	48 8b 78 20          	mov    0x20(%rax),%rdi
  80045d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800461:	48 8b 50 28          	mov    0x28(%rax),%rdx
  800465:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800469:	48 8b 70 18          	mov    0x18(%rax),%rsi
  80046d:	8b 4d ec             	mov    -0x14(%rbp),%ecx
  800470:	8b 85 cc fb ff ff    	mov    -0x434(%rbp),%eax
  800476:	45 89 c1             	mov    %r8d,%r9d
  800479:	49 89 f8             	mov    %rdi,%r8
  80047c:	89 c7                	mov    %eax,%edi
  80047e:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  800485:	00 00 00 
  800488:	ff d0                	callq  *%rax
  80048a:	89 45 fc             	mov    %eax,-0x4(%rbp)
									 prgHdr->p_memsz, fileDesc,
									prgHdr->p_filesz, prgHdr->p_offset);
		if (mapStatus < 0)
  80048d:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800491:	79 18                	jns    8004ab <copy_guest_kern_gpa+0x183>
			{
				close(fileDesc);
  800493:	8b 45 ec             	mov    -0x14(%rbp),%eax
  800496:	89 c7                	mov    %eax,%edi
  800498:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  80049f:	00 00 00 
  8004a2:	ff d0                	callq  *%rax
				return -E_NO_SYS; //Unimplemented
  8004a4:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
  8004a9:	eb 23                	jmp    8004ce <copy_guest_kern_gpa+0x1a6>

	struct Proghdr *prgHdr = (struct Proghdr *)(fileData + fileHeader->e_phoff); //add offset to data and move tp prgHdr 
	struct Proghdr *endPrgHdr = prgHdr + fileHeader->e_phnum; // add more to prghdr, 32 bit offset
	
	//prgHdr is already initialized
	for (; prgHdr < endPrgHdr; prgHdr++)
  8004ab:	48 83 45 f0 38       	addq   $0x38,-0x10(%rbp)
  8004b0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8004b4:	48 3b 45 d0          	cmp    -0x30(%rbp),%rax
  8004b8:	72 85                	jb     80043f <copy_guest_kern_gpa+0x117>
				close(fileDesc);
				return -E_NO_SYS; //Unimplemented
			}
		}
	}
	close(fileDesc);	//closure upon successful read
  8004ba:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8004bd:	89 c7                	mov    %eax,%edi
  8004bf:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  8004c6:	00 00 00 
  8004c9:	ff d0                	callq  *%rax
	return mapStatus;
  8004cb:	8b 45 fc             	mov    -0x4(%rbp),%eax
}
  8004ce:	c9                   	leaveq 
  8004cf:	c3                   	retq   

00000000008004d0 <umain>:

void umain(int argc, char **argv)
{
  8004d0:	55                   	push   %rbp
  8004d1:	48 89 e5             	mov    %rsp,%rbp
  8004d4:	48 83 ec 60          	sub    $0x60,%rsp
  8004d8:	89 7d ac             	mov    %edi,-0x54(%rbp)
  8004db:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
	int ret;
	envid_t guest;
	char filename_buffer[50]; // buffer to save the path
	int vmdisk_number;
	int r;
	if ((ret = sys_env_mkguest(GUEST_MEM_SZ, JOS_ENTRY)) < 0)
  8004df:	be 00 70 00 00       	mov    $0x7000,%esi
  8004e4:	bf 00 00 00 01       	mov    $0x1000000,%edi
  8004e9:	48 b8 9c 22 80 00 00 	movabs $0x80229c,%rax
  8004f0:	00 00 00 
  8004f3:	ff d0                	callq  *%rax
  8004f5:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8004f8:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8004fc:	79 2c                	jns    80052a <umain+0x5a>
	{
		cprintf("Error creating a guest OS env: %e\n", ret);
  8004fe:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800501:	89 c6                	mov    %eax,%esi
  800503:	48 bf 08 48 80 00 00 	movabs $0x804808,%rdi
  80050a:	00 00 00 
  80050d:	b8 00 00 00 00       	mov    $0x0,%eax
  800512:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  800519:	00 00 00 
  80051c:	ff d2                	callq  *%rdx
		exit();
  80051e:	48 b8 c6 07 80 00 00 	movabs $0x8007c6,%rax
  800525:	00 00 00 
  800528:	ff d0                	callq  *%rax
	}
	guest = ret;
  80052a:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80052d:	89 45 f8             	mov    %eax,-0x8(%rbp)

	// Copy the guest kernel code into guest phys mem.
	if ((ret = copy_guest_kern_gpa(guest, GUEST_KERN)) < 0)
  800530:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800533:	48 be 2b 48 80 00 00 	movabs $0x80482b,%rsi
  80053a:	00 00 00 
  80053d:	89 c7                	mov    %eax,%edi
  80053f:	48 b8 28 03 80 00 00 	movabs $0x800328,%rax
  800546:	00 00 00 
  800549:	ff d0                	callq  *%rax
  80054b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80054e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  800552:	79 2c                	jns    800580 <umain+0xb0>
	{
		cprintf("Error copying page into the guest - %d\n.", ret);
  800554:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800557:	89 c6                	mov    %eax,%esi
  800559:	48 bf 38 48 80 00 00 	movabs $0x804838,%rdi
  800560:	00 00 00 
  800563:	b8 00 00 00 00       	mov    $0x0,%eax
  800568:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  80056f:	00 00 00 
  800572:	ff d2                	callq  *%rdx
		exit();
  800574:	48 b8 c6 07 80 00 00 	movabs $0x8007c6,%rax
  80057b:	00 00 00 
  80057e:	ff d0                	callq  *%rax
	}

	// Now copy the bootloader.
	int fd;
	if ((fd = open(GUEST_BOOT, O_RDONLY)) < 0)
  800580:	be 00 00 00 00       	mov    $0x0,%esi
  800585:	48 bf 61 48 80 00 00 	movabs $0x804861,%rdi
  80058c:	00 00 00 
  80058f:	48 b8 d2 2d 80 00 00 	movabs $0x802dd2,%rax
  800596:	00 00 00 
  800599:	ff d0                	callq  *%rax
  80059b:	89 45 f4             	mov    %eax,-0xc(%rbp)
  80059e:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  8005a2:	79 36                	jns    8005da <umain+0x10a>
	{
		cprintf("open %s for read: %e\n", GUEST_BOOT, fd);
  8005a4:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8005a7:	89 c2                	mov    %eax,%edx
  8005a9:	48 be 61 48 80 00 00 	movabs $0x804861,%rsi
  8005b0:	00 00 00 
  8005b3:	48 bf 6b 48 80 00 00 	movabs $0x80486b,%rdi
  8005ba:	00 00 00 
  8005bd:	b8 00 00 00 00       	mov    $0x0,%eax
  8005c2:	48 b9 22 0a 80 00 00 	movabs $0x800a22,%rcx
  8005c9:	00 00 00 
  8005cc:	ff d1                	callq  *%rcx
		exit();
  8005ce:	48 b8 c6 07 80 00 00 	movabs $0x8007c6,%rax
  8005d5:	00 00 00 
  8005d8:	ff d0                	callq  *%rax
	}

	// sizeof(bootloader) < 512.
	if ((ret = map_in_guest(guest, JOS_ENTRY, 512, fd, 512, 0)) < 0)
  8005da:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8005dd:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8005e0:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8005e6:	41 b8 00 02 00 00    	mov    $0x200,%r8d
  8005ec:	89 d1                	mov    %edx,%ecx
  8005ee:	ba 00 02 00 00       	mov    $0x200,%edx
  8005f3:	be 00 70 00 00       	mov    $0x7000,%esi
  8005f8:	89 c7                	mov    %eax,%edi
  8005fa:	48 b8 43 00 80 00 00 	movabs $0x800043,%rax
  800601:	00 00 00 
  800604:	ff d0                	callq  *%rax
  800606:	89 45 fc             	mov    %eax,-0x4(%rbp)
  800609:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80060d:	79 2c                	jns    80063b <umain+0x16b>
	{
		cprintf("Error mapping bootloader into the guest - %d\n.", ret);
  80060f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  800612:	89 c6                	mov    %eax,%esi
  800614:	48 bf 88 48 80 00 00 	movabs $0x804888,%rdi
  80061b:	00 00 00 
  80061e:	b8 00 00 00 00       	mov    $0x0,%eax
  800623:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  80062a:	00 00 00 
  80062d:	ff d2                	callq  *%rdx
		exit();
  80062f:	48 b8 c6 07 80 00 00 	movabs $0x8007c6,%rax
  800636:	00 00 00 
  800639:	ff d0                	callq  *%rax
	}
#ifndef VMM_GUEST
	sys_vmx_incr_vmdisk_number(); // increase the vmdisk number
  80063b:	b8 00 00 00 00       	mov    $0x0,%eax
  800640:	48 ba a6 23 80 00 00 	movabs $0x8023a6,%rdx
  800647:	00 00 00 
  80064a:	ff d2                	callq  *%rdx
	// create a new guest disk image

	vmdisk_number = sys_vmx_get_vmdisk_number();
  80064c:	b8 00 00 00 00       	mov    $0x0,%eax
  800651:	48 ba 68 23 80 00 00 	movabs $0x802368,%rdx
  800658:	00 00 00 
  80065b:	ff d2                	callq  *%rdx
  80065d:	89 45 f0             	mov    %eax,-0x10(%rbp)
	snprintf(filename_buffer, 50, "/vmm/fs%d.img", vmdisk_number);
  800660:	8b 55 f0             	mov    -0x10(%rbp),%edx
  800663:	48 8d 45 b0          	lea    -0x50(%rbp),%rax
  800667:	89 d1                	mov    %edx,%ecx
  800669:	48 ba b7 48 80 00 00 	movabs $0x8048b7,%rdx
  800670:	00 00 00 
  800673:	be 32 00 00 00       	mov    $0x32,%esi
  800678:	48 89 c7             	mov    %rax,%rdi
  80067b:	b8 00 00 00 00       	mov    $0x0,%eax
  800680:	49 b8 8a 14 80 00 00 	movabs $0x80148a,%r8
  800687:	00 00 00 
  80068a:	41 ff d0             	callq  *%r8

	cprintf("Creating a new virtual HDD at /vmm/fs%d.img\n", vmdisk_number);
  80068d:	8b 45 f0             	mov    -0x10(%rbp),%eax
  800690:	89 c6                	mov    %eax,%esi
  800692:	48 bf c8 48 80 00 00 	movabs $0x8048c8,%rdi
  800699:	00 00 00 
  80069c:	b8 00 00 00 00       	mov    $0x0,%eax
  8006a1:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  8006a8:	00 00 00 
  8006ab:	ff d2                	callq  *%rdx
	r = copy("vmm/clean-fs.img", filename_buffer);
  8006ad:	48 8d 45 b0          	lea    -0x50(%rbp),%rax
  8006b1:	48 89 c6             	mov    %rax,%rsi
  8006b4:	48 bf f5 48 80 00 00 	movabs $0x8048f5,%rdi
  8006bb:	00 00 00 
  8006be:	48 b8 34 32 80 00 00 	movabs $0x803234,%rax
  8006c5:	00 00 00 
  8006c8:	ff d0                	callq  *%rax
  8006ca:	89 45 ec             	mov    %eax,-0x14(%rbp)

	if (r < 0)
  8006cd:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  8006d1:	79 2c                	jns    8006ff <umain+0x22f>
	{
		cprintf("Create new virtual HDD failed: %e\n", r);
  8006d3:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8006d6:	89 c6                	mov    %eax,%esi
  8006d8:	48 bf 08 49 80 00 00 	movabs $0x804908,%rdi
  8006df:	00 00 00 
  8006e2:	b8 00 00 00 00       	mov    $0x0,%eax
  8006e7:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  8006ee:	00 00 00 
  8006f1:	ff d2                	callq  *%rdx
		exit();
  8006f3:	48 b8 c6 07 80 00 00 	movabs $0x8007c6,%rax
  8006fa:	00 00 00 
  8006fd:	ff d0                	callq  *%rax
	}

	cprintf("Create VHD finished\n");
  8006ff:	48 bf 2b 49 80 00 00 	movabs $0x80492b,%rdi
  800706:	00 00 00 
  800709:	b8 00 00 00 00       	mov    $0x0,%eax
  80070e:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  800715:	00 00 00 
  800718:	ff d2                	callq  *%rdx
#endif
	// Mark the guest as runnable.
	sys_env_set_status(guest, ENV_RUNNABLE);
  80071a:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80071d:	be 02 00 00 00       	mov    $0x2,%esi
  800722:	89 c7                	mov    %eax,%edi
  800724:	48 b8 fb 1f 80 00 00 	movabs $0x801ffb,%rax
  80072b:	00 00 00 
  80072e:	ff d0                	callq  *%rax
	wait(guest);
  800730:	8b 45 f8             	mov    -0x8(%rbp),%eax
  800733:	89 c7                	mov    %eax,%edi
  800735:	48 b8 e4 41 80 00 00 	movabs $0x8041e4,%rax
  80073c:	00 00 00 
  80073f:	ff d0                	callq  *%rax
}
  800741:	c9                   	leaveq 
  800742:	c3                   	retq   

0000000000800743 <libmain>:
  800743:	55                   	push   %rbp
  800744:	48 89 e5             	mov    %rsp,%rbp
  800747:	48 83 ec 10          	sub    $0x10,%rsp
  80074b:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80074e:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  800752:	48 b8 8a 1e 80 00 00 	movabs $0x801e8a,%rax
  800759:	00 00 00 
  80075c:	ff d0                	callq  *%rax
  80075e:	25 ff 03 00 00       	and    $0x3ff,%eax
  800763:	48 98                	cltq   
  800765:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  80076c:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  800773:	00 00 00 
  800776:	48 01 c2             	add    %rax,%rdx
  800779:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  800780:	00 00 00 
  800783:	48 89 10             	mov    %rdx,(%rax)
  800786:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80078a:	7e 14                	jle    8007a0 <libmain+0x5d>
  80078c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800790:	48 8b 10             	mov    (%rax),%rdx
  800793:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  80079a:	00 00 00 
  80079d:	48 89 10             	mov    %rdx,(%rax)
  8007a0:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8007a4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8007a7:	48 89 d6             	mov    %rdx,%rsi
  8007aa:	89 c7                	mov    %eax,%edi
  8007ac:	48 b8 d0 04 80 00 00 	movabs $0x8004d0,%rax
  8007b3:	00 00 00 
  8007b6:	ff d0                	callq  *%rax
  8007b8:	48 b8 c6 07 80 00 00 	movabs $0x8007c6,%rax
  8007bf:	00 00 00 
  8007c2:	ff d0                	callq  *%rax
  8007c4:	c9                   	leaveq 
  8007c5:	c3                   	retq   

00000000008007c6 <exit>:
  8007c6:	55                   	push   %rbp
  8007c7:	48 89 e5             	mov    %rsp,%rbp
  8007ca:	48 b8 25 27 80 00 00 	movabs $0x802725,%rax
  8007d1:	00 00 00 
  8007d4:	ff d0                	callq  *%rax
  8007d6:	bf 00 00 00 00       	mov    $0x0,%edi
  8007db:	48 b8 46 1e 80 00 00 	movabs $0x801e46,%rax
  8007e2:	00 00 00 
  8007e5:	ff d0                	callq  *%rax
  8007e7:	5d                   	pop    %rbp
  8007e8:	c3                   	retq   

00000000008007e9 <_panic>:
  8007e9:	55                   	push   %rbp
  8007ea:	48 89 e5             	mov    %rsp,%rbp
  8007ed:	53                   	push   %rbx
  8007ee:	48 81 ec f8 00 00 00 	sub    $0xf8,%rsp
  8007f5:	48 89 bd 18 ff ff ff 	mov    %rdi,-0xe8(%rbp)
  8007fc:	89 b5 14 ff ff ff    	mov    %esi,-0xec(%rbp)
  800802:	48 89 8d 58 ff ff ff 	mov    %rcx,-0xa8(%rbp)
  800809:	4c 89 85 60 ff ff ff 	mov    %r8,-0xa0(%rbp)
  800810:	4c 89 8d 68 ff ff ff 	mov    %r9,-0x98(%rbp)
  800817:	84 c0                	test   %al,%al
  800819:	74 23                	je     80083e <_panic+0x55>
  80081b:	0f 29 85 70 ff ff ff 	movaps %xmm0,-0x90(%rbp)
  800822:	0f 29 4d 80          	movaps %xmm1,-0x80(%rbp)
  800826:	0f 29 55 90          	movaps %xmm2,-0x70(%rbp)
  80082a:	0f 29 5d a0          	movaps %xmm3,-0x60(%rbp)
  80082e:	0f 29 65 b0          	movaps %xmm4,-0x50(%rbp)
  800832:	0f 29 6d c0          	movaps %xmm5,-0x40(%rbp)
  800836:	0f 29 75 d0          	movaps %xmm6,-0x30(%rbp)
  80083a:	0f 29 7d e0          	movaps %xmm7,-0x20(%rbp)
  80083e:	48 89 95 08 ff ff ff 	mov    %rdx,-0xf8(%rbp)
  800845:	c7 85 28 ff ff ff 18 	movl   $0x18,-0xd8(%rbp)
  80084c:	00 00 00 
  80084f:	c7 85 2c ff ff ff 30 	movl   $0x30,-0xd4(%rbp)
  800856:	00 00 00 
  800859:	48 8d 45 10          	lea    0x10(%rbp),%rax
  80085d:	48 89 85 30 ff ff ff 	mov    %rax,-0xd0(%rbp)
  800864:	48 8d 85 40 ff ff ff 	lea    -0xc0(%rbp),%rax
  80086b:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  800872:	48 b8 00 70 80 00 00 	movabs $0x807000,%rax
  800879:	00 00 00 
  80087c:	48 8b 18             	mov    (%rax),%rbx
  80087f:	48 b8 8a 1e 80 00 00 	movabs $0x801e8a,%rax
  800886:	00 00 00 
  800889:	ff d0                	callq  *%rax
  80088b:	8b 8d 14 ff ff ff    	mov    -0xec(%rbp),%ecx
  800891:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  800898:	41 89 c8             	mov    %ecx,%r8d
  80089b:	48 89 d1             	mov    %rdx,%rcx
  80089e:	48 89 da             	mov    %rbx,%rdx
  8008a1:	89 c6                	mov    %eax,%esi
  8008a3:	48 bf 50 49 80 00 00 	movabs $0x804950,%rdi
  8008aa:	00 00 00 
  8008ad:	b8 00 00 00 00       	mov    $0x0,%eax
  8008b2:	49 b9 22 0a 80 00 00 	movabs $0x800a22,%r9
  8008b9:	00 00 00 
  8008bc:	41 ff d1             	callq  *%r9
  8008bf:	48 8d 95 28 ff ff ff 	lea    -0xd8(%rbp),%rdx
  8008c6:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  8008cd:	48 89 d6             	mov    %rdx,%rsi
  8008d0:	48 89 c7             	mov    %rax,%rdi
  8008d3:	48 b8 76 09 80 00 00 	movabs $0x800976,%rax
  8008da:	00 00 00 
  8008dd:	ff d0                	callq  *%rax
  8008df:	48 bf 73 49 80 00 00 	movabs $0x804973,%rdi
  8008e6:	00 00 00 
  8008e9:	b8 00 00 00 00       	mov    $0x0,%eax
  8008ee:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  8008f5:	00 00 00 
  8008f8:	ff d2                	callq  *%rdx
  8008fa:	cc                   	int3   
  8008fb:	eb fd                	jmp    8008fa <_panic+0x111>

00000000008008fd <putch>:
  8008fd:	55                   	push   %rbp
  8008fe:	48 89 e5             	mov    %rsp,%rbp
  800901:	48 83 ec 10          	sub    $0x10,%rsp
  800905:	89 7d fc             	mov    %edi,-0x4(%rbp)
  800908:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80090c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800910:	8b 00                	mov    (%rax),%eax
  800912:	8d 48 01             	lea    0x1(%rax),%ecx
  800915:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  800919:	89 0a                	mov    %ecx,(%rdx)
  80091b:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80091e:	89 d1                	mov    %edx,%ecx
  800920:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  800924:	48 98                	cltq   
  800926:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  80092a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80092e:	8b 00                	mov    (%rax),%eax
  800930:	3d ff 00 00 00       	cmp    $0xff,%eax
  800935:	75 2c                	jne    800963 <putch+0x66>
  800937:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80093b:	8b 00                	mov    (%rax),%eax
  80093d:	48 98                	cltq   
  80093f:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  800943:	48 83 c2 08          	add    $0x8,%rdx
  800947:	48 89 c6             	mov    %rax,%rsi
  80094a:	48 89 d7             	mov    %rdx,%rdi
  80094d:	48 b8 be 1d 80 00 00 	movabs $0x801dbe,%rax
  800954:	00 00 00 
  800957:	ff d0                	callq  *%rax
  800959:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80095d:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  800963:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800967:	8b 40 04             	mov    0x4(%rax),%eax
  80096a:	8d 50 01             	lea    0x1(%rax),%edx
  80096d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  800971:	89 50 04             	mov    %edx,0x4(%rax)
  800974:	c9                   	leaveq 
  800975:	c3                   	retq   

0000000000800976 <vcprintf>:
  800976:	55                   	push   %rbp
  800977:	48 89 e5             	mov    %rsp,%rbp
  80097a:	48 81 ec 40 01 00 00 	sub    $0x140,%rsp
  800981:	48 89 bd c8 fe ff ff 	mov    %rdi,-0x138(%rbp)
  800988:	48 89 b5 c0 fe ff ff 	mov    %rsi,-0x140(%rbp)
  80098f:	48 8d 85 d8 fe ff ff 	lea    -0x128(%rbp),%rax
  800996:	48 8b 95 c0 fe ff ff 	mov    -0x140(%rbp),%rdx
  80099d:	48 8b 0a             	mov    (%rdx),%rcx
  8009a0:	48 89 08             	mov    %rcx,(%rax)
  8009a3:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  8009a7:	48 89 48 08          	mov    %rcx,0x8(%rax)
  8009ab:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  8009af:	48 89 50 10          	mov    %rdx,0x10(%rax)
  8009b3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%rbp)
  8009ba:	00 00 00 
  8009bd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%rbp)
  8009c4:	00 00 00 
  8009c7:	48 8d 8d d8 fe ff ff 	lea    -0x128(%rbp),%rcx
  8009ce:	48 8b 95 c8 fe ff ff 	mov    -0x138(%rbp),%rdx
  8009d5:	48 8d 85 f0 fe ff ff 	lea    -0x110(%rbp),%rax
  8009dc:	48 89 c6             	mov    %rax,%rsi
  8009df:	48 bf fd 08 80 00 00 	movabs $0x8008fd,%rdi
  8009e6:	00 00 00 
  8009e9:	48 b8 d5 0d 80 00 00 	movabs $0x800dd5,%rax
  8009f0:	00 00 00 
  8009f3:	ff d0                	callq  *%rax
  8009f5:	8b 85 f0 fe ff ff    	mov    -0x110(%rbp),%eax
  8009fb:	48 98                	cltq   
  8009fd:	48 8d 95 f0 fe ff ff 	lea    -0x110(%rbp),%rdx
  800a04:	48 83 c2 08          	add    $0x8,%rdx
  800a08:	48 89 c6             	mov    %rax,%rsi
  800a0b:	48 89 d7             	mov    %rdx,%rdi
  800a0e:	48 b8 be 1d 80 00 00 	movabs $0x801dbe,%rax
  800a15:	00 00 00 
  800a18:	ff d0                	callq  *%rax
  800a1a:	8b 85 f4 fe ff ff    	mov    -0x10c(%rbp),%eax
  800a20:	c9                   	leaveq 
  800a21:	c3                   	retq   

0000000000800a22 <cprintf>:
  800a22:	55                   	push   %rbp
  800a23:	48 89 e5             	mov    %rsp,%rbp
  800a26:	48 81 ec 00 01 00 00 	sub    $0x100,%rsp
  800a2d:	48 89 b5 58 ff ff ff 	mov    %rsi,-0xa8(%rbp)
  800a34:	48 89 95 60 ff ff ff 	mov    %rdx,-0xa0(%rbp)
  800a3b:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  800a42:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  800a49:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  800a50:	84 c0                	test   %al,%al
  800a52:	74 20                	je     800a74 <cprintf+0x52>
  800a54:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  800a58:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  800a5c:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  800a60:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  800a64:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  800a68:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  800a6c:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  800a70:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  800a74:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  800a7b:	c7 85 30 ff ff ff 08 	movl   $0x8,-0xd0(%rbp)
  800a82:	00 00 00 
  800a85:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  800a8c:	00 00 00 
  800a8f:	48 8d 45 10          	lea    0x10(%rbp),%rax
  800a93:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  800a9a:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  800aa1:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  800aa8:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  800aaf:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  800ab6:	48 8b 0a             	mov    (%rdx),%rcx
  800ab9:	48 89 08             	mov    %rcx,(%rax)
  800abc:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800ac0:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800ac4:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  800ac8:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800acc:	48 8d 95 18 ff ff ff 	lea    -0xe8(%rbp),%rdx
  800ad3:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  800ada:	48 89 d6             	mov    %rdx,%rsi
  800add:	48 89 c7             	mov    %rax,%rdi
  800ae0:	48 b8 76 09 80 00 00 	movabs $0x800976,%rax
  800ae7:	00 00 00 
  800aea:	ff d0                	callq  *%rax
  800aec:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  800af2:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  800af8:	c9                   	leaveq 
  800af9:	c3                   	retq   

0000000000800afa <printnum>:
  800afa:	55                   	push   %rbp
  800afb:	48 89 e5             	mov    %rsp,%rbp
  800afe:	53                   	push   %rbx
  800aff:	48 83 ec 38          	sub    $0x38,%rsp
  800b03:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800b07:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  800b0b:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  800b0f:	89 4d d4             	mov    %ecx,-0x2c(%rbp)
  800b12:	44 89 45 d0          	mov    %r8d,-0x30(%rbp)
  800b16:	44 89 4d cc          	mov    %r9d,-0x34(%rbp)
  800b1a:	8b 45 d4             	mov    -0x2c(%rbp),%eax
  800b1d:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  800b21:	77 3b                	ja     800b5e <printnum+0x64>
  800b23:	8b 45 d0             	mov    -0x30(%rbp),%eax
  800b26:	44 8d 40 ff          	lea    -0x1(%rax),%r8d
  800b2a:	8b 5d d4             	mov    -0x2c(%rbp),%ebx
  800b2d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800b31:	ba 00 00 00 00       	mov    $0x0,%edx
  800b36:	48 f7 f3             	div    %rbx
  800b39:	48 89 c2             	mov    %rax,%rdx
  800b3c:	8b 7d cc             	mov    -0x34(%rbp),%edi
  800b3f:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  800b42:	48 8b 75 e0          	mov    -0x20(%rbp),%rsi
  800b46:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b4a:	41 89 f9             	mov    %edi,%r9d
  800b4d:	48 89 c7             	mov    %rax,%rdi
  800b50:	48 b8 fa 0a 80 00 00 	movabs $0x800afa,%rax
  800b57:	00 00 00 
  800b5a:	ff d0                	callq  *%rax
  800b5c:	eb 1e                	jmp    800b7c <printnum+0x82>
  800b5e:	eb 12                	jmp    800b72 <printnum+0x78>
  800b60:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  800b64:	8b 55 cc             	mov    -0x34(%rbp),%edx
  800b67:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800b6b:	48 89 ce             	mov    %rcx,%rsi
  800b6e:	89 d7                	mov    %edx,%edi
  800b70:	ff d0                	callq  *%rax
  800b72:	83 6d d0 01          	subl   $0x1,-0x30(%rbp)
  800b76:	83 7d d0 00          	cmpl   $0x0,-0x30(%rbp)
  800b7a:	7f e4                	jg     800b60 <printnum+0x66>
  800b7c:	8b 4d d4             	mov    -0x2c(%rbp),%ecx
  800b7f:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  800b83:	ba 00 00 00 00       	mov    $0x0,%edx
  800b88:	48 f7 f1             	div    %rcx
  800b8b:	48 89 d0             	mov    %rdx,%rax
  800b8e:	48 ba 70 4b 80 00 00 	movabs $0x804b70,%rdx
  800b95:	00 00 00 
  800b98:	0f b6 04 02          	movzbl (%rdx,%rax,1),%eax
  800b9c:	0f be d0             	movsbl %al,%edx
  800b9f:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  800ba3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ba7:	48 89 ce             	mov    %rcx,%rsi
  800baa:	89 d7                	mov    %edx,%edi
  800bac:	ff d0                	callq  *%rax
  800bae:	48 83 c4 38          	add    $0x38,%rsp
  800bb2:	5b                   	pop    %rbx
  800bb3:	5d                   	pop    %rbp
  800bb4:	c3                   	retq   

0000000000800bb5 <getuint>:
  800bb5:	55                   	push   %rbp
  800bb6:	48 89 e5             	mov    %rsp,%rbp
  800bb9:	48 83 ec 1c          	sub    $0x1c,%rsp
  800bbd:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800bc1:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800bc4:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800bc8:	7e 52                	jle    800c1c <getuint+0x67>
  800bca:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bce:	8b 00                	mov    (%rax),%eax
  800bd0:	83 f8 30             	cmp    $0x30,%eax
  800bd3:	73 24                	jae    800bf9 <getuint+0x44>
  800bd5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bd9:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800bdd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800be1:	8b 00                	mov    (%rax),%eax
  800be3:	89 c0                	mov    %eax,%eax
  800be5:	48 01 d0             	add    %rdx,%rax
  800be8:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800bec:	8b 12                	mov    (%rdx),%edx
  800bee:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800bf1:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800bf5:	89 0a                	mov    %ecx,(%rdx)
  800bf7:	eb 17                	jmp    800c10 <getuint+0x5b>
  800bf9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800bfd:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800c01:	48 89 d0             	mov    %rdx,%rax
  800c04:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800c08:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c0c:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800c10:	48 8b 00             	mov    (%rax),%rax
  800c13:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800c17:	e9 a3 00 00 00       	jmpq   800cbf <getuint+0x10a>
  800c1c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800c20:	74 4f                	je     800c71 <getuint+0xbc>
  800c22:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c26:	8b 00                	mov    (%rax),%eax
  800c28:	83 f8 30             	cmp    $0x30,%eax
  800c2b:	73 24                	jae    800c51 <getuint+0x9c>
  800c2d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c31:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800c35:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c39:	8b 00                	mov    (%rax),%eax
  800c3b:	89 c0                	mov    %eax,%eax
  800c3d:	48 01 d0             	add    %rdx,%rax
  800c40:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c44:	8b 12                	mov    (%rdx),%edx
  800c46:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800c49:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c4d:	89 0a                	mov    %ecx,(%rdx)
  800c4f:	eb 17                	jmp    800c68 <getuint+0xb3>
  800c51:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c55:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800c59:	48 89 d0             	mov    %rdx,%rax
  800c5c:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800c60:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c64:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800c68:	48 8b 00             	mov    (%rax),%rax
  800c6b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800c6f:	eb 4e                	jmp    800cbf <getuint+0x10a>
  800c71:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c75:	8b 00                	mov    (%rax),%eax
  800c77:	83 f8 30             	cmp    $0x30,%eax
  800c7a:	73 24                	jae    800ca0 <getuint+0xeb>
  800c7c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c80:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800c84:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800c88:	8b 00                	mov    (%rax),%eax
  800c8a:	89 c0                	mov    %eax,%eax
  800c8c:	48 01 d0             	add    %rdx,%rax
  800c8f:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c93:	8b 12                	mov    (%rdx),%edx
  800c95:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800c98:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800c9c:	89 0a                	mov    %ecx,(%rdx)
  800c9e:	eb 17                	jmp    800cb7 <getuint+0x102>
  800ca0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ca4:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800ca8:	48 89 d0             	mov    %rdx,%rax
  800cab:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800caf:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800cb3:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800cb7:	8b 00                	mov    (%rax),%eax
  800cb9:	89 c0                	mov    %eax,%eax
  800cbb:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800cbf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800cc3:	c9                   	leaveq 
  800cc4:	c3                   	retq   

0000000000800cc5 <getint>:
  800cc5:	55                   	push   %rbp
  800cc6:	48 89 e5             	mov    %rsp,%rbp
  800cc9:	48 83 ec 1c          	sub    $0x1c,%rsp
  800ccd:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  800cd1:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  800cd4:	83 7d e4 01          	cmpl   $0x1,-0x1c(%rbp)
  800cd8:	7e 52                	jle    800d2c <getint+0x67>
  800cda:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800cde:	8b 00                	mov    (%rax),%eax
  800ce0:	83 f8 30             	cmp    $0x30,%eax
  800ce3:	73 24                	jae    800d09 <getint+0x44>
  800ce5:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800ce9:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800ced:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800cf1:	8b 00                	mov    (%rax),%eax
  800cf3:	89 c0                	mov    %eax,%eax
  800cf5:	48 01 d0             	add    %rdx,%rax
  800cf8:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800cfc:	8b 12                	mov    (%rdx),%edx
  800cfe:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800d01:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800d05:	89 0a                	mov    %ecx,(%rdx)
  800d07:	eb 17                	jmp    800d20 <getint+0x5b>
  800d09:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d0d:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800d11:	48 89 d0             	mov    %rdx,%rax
  800d14:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800d18:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800d1c:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800d20:	48 8b 00             	mov    (%rax),%rax
  800d23:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800d27:	e9 a3 00 00 00       	jmpq   800dcf <getint+0x10a>
  800d2c:	83 7d e4 00          	cmpl   $0x0,-0x1c(%rbp)
  800d30:	74 4f                	je     800d81 <getint+0xbc>
  800d32:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d36:	8b 00                	mov    (%rax),%eax
  800d38:	83 f8 30             	cmp    $0x30,%eax
  800d3b:	73 24                	jae    800d61 <getint+0x9c>
  800d3d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d41:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800d45:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d49:	8b 00                	mov    (%rax),%eax
  800d4b:	89 c0                	mov    %eax,%eax
  800d4d:	48 01 d0             	add    %rdx,%rax
  800d50:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800d54:	8b 12                	mov    (%rdx),%edx
  800d56:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800d59:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800d5d:	89 0a                	mov    %ecx,(%rdx)
  800d5f:	eb 17                	jmp    800d78 <getint+0xb3>
  800d61:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d65:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800d69:	48 89 d0             	mov    %rdx,%rax
  800d6c:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800d70:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800d74:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800d78:	48 8b 00             	mov    (%rax),%rax
  800d7b:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800d7f:	eb 4e                	jmp    800dcf <getint+0x10a>
  800d81:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d85:	8b 00                	mov    (%rax),%eax
  800d87:	83 f8 30             	cmp    $0x30,%eax
  800d8a:	73 24                	jae    800db0 <getint+0xeb>
  800d8c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d90:	48 8b 50 10          	mov    0x10(%rax),%rdx
  800d94:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800d98:	8b 00                	mov    (%rax),%eax
  800d9a:	89 c0                	mov    %eax,%eax
  800d9c:	48 01 d0             	add    %rdx,%rax
  800d9f:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800da3:	8b 12                	mov    (%rdx),%edx
  800da5:	8d 4a 08             	lea    0x8(%rdx),%ecx
  800da8:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800dac:	89 0a                	mov    %ecx,(%rdx)
  800dae:	eb 17                	jmp    800dc7 <getint+0x102>
  800db0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  800db4:	48 8b 50 08          	mov    0x8(%rax),%rdx
  800db8:	48 89 d0             	mov    %rdx,%rax
  800dbb:	48 8d 4a 08          	lea    0x8(%rdx),%rcx
  800dbf:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  800dc3:	48 89 4a 08          	mov    %rcx,0x8(%rdx)
  800dc7:	8b 00                	mov    (%rax),%eax
  800dc9:	48 98                	cltq   
  800dcb:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  800dcf:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  800dd3:	c9                   	leaveq 
  800dd4:	c3                   	retq   

0000000000800dd5 <vprintfmt>:
  800dd5:	55                   	push   %rbp
  800dd6:	48 89 e5             	mov    %rsp,%rbp
  800dd9:	41 54                	push   %r12
  800ddb:	53                   	push   %rbx
  800ddc:	48 83 ec 60          	sub    $0x60,%rsp
  800de0:	48 89 7d a8          	mov    %rdi,-0x58(%rbp)
  800de4:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  800de8:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800dec:	48 89 4d 90          	mov    %rcx,-0x70(%rbp)
  800df0:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  800df4:	48 8b 55 90          	mov    -0x70(%rbp),%rdx
  800df8:	48 8b 0a             	mov    (%rdx),%rcx
  800dfb:	48 89 08             	mov    %rcx,(%rax)
  800dfe:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  800e02:	48 89 48 08          	mov    %rcx,0x8(%rax)
  800e06:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  800e0a:	48 89 50 10          	mov    %rdx,0x10(%rax)
  800e0e:	eb 17                	jmp    800e27 <vprintfmt+0x52>
  800e10:	85 db                	test   %ebx,%ebx
  800e12:	0f 84 cc 04 00 00    	je     8012e4 <vprintfmt+0x50f>
  800e18:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  800e1c:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800e20:	48 89 d6             	mov    %rdx,%rsi
  800e23:	89 df                	mov    %ebx,%edi
  800e25:	ff d0                	callq  *%rax
  800e27:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800e2b:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800e2f:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800e33:	0f b6 00             	movzbl (%rax),%eax
  800e36:	0f b6 d8             	movzbl %al,%ebx
  800e39:	83 fb 25             	cmp    $0x25,%ebx
  800e3c:	75 d2                	jne    800e10 <vprintfmt+0x3b>
  800e3e:	c6 45 d3 20          	movb   $0x20,-0x2d(%rbp)
  800e42:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%rbp)
  800e49:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800e50:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  800e57:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%rbp)
  800e5e:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800e62:	48 8d 50 01          	lea    0x1(%rax),%rdx
  800e66:	48 89 55 98          	mov    %rdx,-0x68(%rbp)
  800e6a:	0f b6 00             	movzbl (%rax),%eax
  800e6d:	0f b6 d8             	movzbl %al,%ebx
  800e70:	8d 43 dd             	lea    -0x23(%rbx),%eax
  800e73:	83 f8 55             	cmp    $0x55,%eax
  800e76:	0f 87 34 04 00 00    	ja     8012b0 <vprintfmt+0x4db>
  800e7c:	89 c0                	mov    %eax,%eax
  800e7e:	48 8d 14 c5 00 00 00 	lea    0x0(,%rax,8),%rdx
  800e85:	00 
  800e86:	48 b8 98 4b 80 00 00 	movabs $0x804b98,%rax
  800e8d:	00 00 00 
  800e90:	48 01 d0             	add    %rdx,%rax
  800e93:	48 8b 00             	mov    (%rax),%rax
  800e96:	ff e0                	jmpq   *%rax
  800e98:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%rbp)
  800e9c:	eb c0                	jmp    800e5e <vprintfmt+0x89>
  800e9e:	c6 45 d3 30          	movb   $0x30,-0x2d(%rbp)
  800ea2:	eb ba                	jmp    800e5e <vprintfmt+0x89>
  800ea4:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%rbp)
  800eab:	8b 55 d8             	mov    -0x28(%rbp),%edx
  800eae:	89 d0                	mov    %edx,%eax
  800eb0:	c1 e0 02             	shl    $0x2,%eax
  800eb3:	01 d0                	add    %edx,%eax
  800eb5:	01 c0                	add    %eax,%eax
  800eb7:	01 d8                	add    %ebx,%eax
  800eb9:	83 e8 30             	sub    $0x30,%eax
  800ebc:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800ebf:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  800ec3:	0f b6 00             	movzbl (%rax),%eax
  800ec6:	0f be d8             	movsbl %al,%ebx
  800ec9:	83 fb 2f             	cmp    $0x2f,%ebx
  800ecc:	7e 0c                	jle    800eda <vprintfmt+0x105>
  800ece:	83 fb 39             	cmp    $0x39,%ebx
  800ed1:	7f 07                	jg     800eda <vprintfmt+0x105>
  800ed3:	48 83 45 98 01       	addq   $0x1,-0x68(%rbp)
  800ed8:	eb d1                	jmp    800eab <vprintfmt+0xd6>
  800eda:	eb 58                	jmp    800f34 <vprintfmt+0x15f>
  800edc:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800edf:	83 f8 30             	cmp    $0x30,%eax
  800ee2:	73 17                	jae    800efb <vprintfmt+0x126>
  800ee4:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800ee8:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800eeb:	89 c0                	mov    %eax,%eax
  800eed:	48 01 d0             	add    %rdx,%rax
  800ef0:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800ef3:	83 c2 08             	add    $0x8,%edx
  800ef6:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800ef9:	eb 0f                	jmp    800f0a <vprintfmt+0x135>
  800efb:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800eff:	48 89 d0             	mov    %rdx,%rax
  800f02:	48 83 c2 08          	add    $0x8,%rdx
  800f06:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800f0a:	8b 00                	mov    (%rax),%eax
  800f0c:	89 45 d8             	mov    %eax,-0x28(%rbp)
  800f0f:	eb 23                	jmp    800f34 <vprintfmt+0x15f>
  800f11:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800f15:	79 0c                	jns    800f23 <vprintfmt+0x14e>
  800f17:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%rbp)
  800f1e:	e9 3b ff ff ff       	jmpq   800e5e <vprintfmt+0x89>
  800f23:	e9 36 ff ff ff       	jmpq   800e5e <vprintfmt+0x89>
  800f28:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%rbp)
  800f2f:	e9 2a ff ff ff       	jmpq   800e5e <vprintfmt+0x89>
  800f34:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  800f38:	79 12                	jns    800f4c <vprintfmt+0x177>
  800f3a:	8b 45 d8             	mov    -0x28(%rbp),%eax
  800f3d:	89 45 dc             	mov    %eax,-0x24(%rbp)
  800f40:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%rbp)
  800f47:	e9 12 ff ff ff       	jmpq   800e5e <vprintfmt+0x89>
  800f4c:	e9 0d ff ff ff       	jmpq   800e5e <vprintfmt+0x89>
  800f51:	83 45 e0 01          	addl   $0x1,-0x20(%rbp)
  800f55:	e9 04 ff ff ff       	jmpq   800e5e <vprintfmt+0x89>
  800f5a:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800f5d:	83 f8 30             	cmp    $0x30,%eax
  800f60:	73 17                	jae    800f79 <vprintfmt+0x1a4>
  800f62:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800f66:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800f69:	89 c0                	mov    %eax,%eax
  800f6b:	48 01 d0             	add    %rdx,%rax
  800f6e:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800f71:	83 c2 08             	add    $0x8,%edx
  800f74:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800f77:	eb 0f                	jmp    800f88 <vprintfmt+0x1b3>
  800f79:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800f7d:	48 89 d0             	mov    %rdx,%rax
  800f80:	48 83 c2 08          	add    $0x8,%rdx
  800f84:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800f88:	8b 10                	mov    (%rax),%edx
  800f8a:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  800f8e:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800f92:	48 89 ce             	mov    %rcx,%rsi
  800f95:	89 d7                	mov    %edx,%edi
  800f97:	ff d0                	callq  *%rax
  800f99:	e9 40 03 00 00       	jmpq   8012de <vprintfmt+0x509>
  800f9e:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800fa1:	83 f8 30             	cmp    $0x30,%eax
  800fa4:	73 17                	jae    800fbd <vprintfmt+0x1e8>
  800fa6:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  800faa:	8b 45 b8             	mov    -0x48(%rbp),%eax
  800fad:	89 c0                	mov    %eax,%eax
  800faf:	48 01 d0             	add    %rdx,%rax
  800fb2:	8b 55 b8             	mov    -0x48(%rbp),%edx
  800fb5:	83 c2 08             	add    $0x8,%edx
  800fb8:	89 55 b8             	mov    %edx,-0x48(%rbp)
  800fbb:	eb 0f                	jmp    800fcc <vprintfmt+0x1f7>
  800fbd:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  800fc1:	48 89 d0             	mov    %rdx,%rax
  800fc4:	48 83 c2 08          	add    $0x8,%rdx
  800fc8:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  800fcc:	8b 18                	mov    (%rax),%ebx
  800fce:	85 db                	test   %ebx,%ebx
  800fd0:	79 02                	jns    800fd4 <vprintfmt+0x1ff>
  800fd2:	f7 db                	neg    %ebx
  800fd4:	83 fb 15             	cmp    $0x15,%ebx
  800fd7:	7f 16                	jg     800fef <vprintfmt+0x21a>
  800fd9:	48 b8 c0 4a 80 00 00 	movabs $0x804ac0,%rax
  800fe0:	00 00 00 
  800fe3:	48 63 d3             	movslq %ebx,%rdx
  800fe6:	4c 8b 24 d0          	mov    (%rax,%rdx,8),%r12
  800fea:	4d 85 e4             	test   %r12,%r12
  800fed:	75 2e                	jne    80101d <vprintfmt+0x248>
  800fef:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  800ff3:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  800ff7:	89 d9                	mov    %ebx,%ecx
  800ff9:	48 ba 81 4b 80 00 00 	movabs $0x804b81,%rdx
  801000:	00 00 00 
  801003:	48 89 c7             	mov    %rax,%rdi
  801006:	b8 00 00 00 00       	mov    $0x0,%eax
  80100b:	49 b8 ed 12 80 00 00 	movabs $0x8012ed,%r8
  801012:	00 00 00 
  801015:	41 ff d0             	callq  *%r8
  801018:	e9 c1 02 00 00       	jmpq   8012de <vprintfmt+0x509>
  80101d:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  801021:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801025:	4c 89 e1             	mov    %r12,%rcx
  801028:	48 ba 8a 4b 80 00 00 	movabs $0x804b8a,%rdx
  80102f:	00 00 00 
  801032:	48 89 c7             	mov    %rax,%rdi
  801035:	b8 00 00 00 00       	mov    $0x0,%eax
  80103a:	49 b8 ed 12 80 00 00 	movabs $0x8012ed,%r8
  801041:	00 00 00 
  801044:	41 ff d0             	callq  *%r8
  801047:	e9 92 02 00 00       	jmpq   8012de <vprintfmt+0x509>
  80104c:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80104f:	83 f8 30             	cmp    $0x30,%eax
  801052:	73 17                	jae    80106b <vprintfmt+0x296>
  801054:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  801058:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80105b:	89 c0                	mov    %eax,%eax
  80105d:	48 01 d0             	add    %rdx,%rax
  801060:	8b 55 b8             	mov    -0x48(%rbp),%edx
  801063:	83 c2 08             	add    $0x8,%edx
  801066:	89 55 b8             	mov    %edx,-0x48(%rbp)
  801069:	eb 0f                	jmp    80107a <vprintfmt+0x2a5>
  80106b:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  80106f:	48 89 d0             	mov    %rdx,%rax
  801072:	48 83 c2 08          	add    $0x8,%rdx
  801076:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  80107a:	4c 8b 20             	mov    (%rax),%r12
  80107d:	4d 85 e4             	test   %r12,%r12
  801080:	75 0a                	jne    80108c <vprintfmt+0x2b7>
  801082:	49 bc 8d 4b 80 00 00 	movabs $0x804b8d,%r12
  801089:	00 00 00 
  80108c:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  801090:	7e 3f                	jle    8010d1 <vprintfmt+0x2fc>
  801092:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%rbp)
  801096:	74 39                	je     8010d1 <vprintfmt+0x2fc>
  801098:	8b 45 d8             	mov    -0x28(%rbp),%eax
  80109b:	48 98                	cltq   
  80109d:	48 89 c6             	mov    %rax,%rsi
  8010a0:	4c 89 e7             	mov    %r12,%rdi
  8010a3:	48 b8 99 15 80 00 00 	movabs $0x801599,%rax
  8010aa:	00 00 00 
  8010ad:	ff d0                	callq  *%rax
  8010af:	29 45 dc             	sub    %eax,-0x24(%rbp)
  8010b2:	eb 17                	jmp    8010cb <vprintfmt+0x2f6>
  8010b4:	0f be 55 d3          	movsbl -0x2d(%rbp),%edx
  8010b8:	48 8b 4d a0          	mov    -0x60(%rbp),%rcx
  8010bc:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8010c0:	48 89 ce             	mov    %rcx,%rsi
  8010c3:	89 d7                	mov    %edx,%edi
  8010c5:	ff d0                	callq  *%rax
  8010c7:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  8010cb:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  8010cf:	7f e3                	jg     8010b4 <vprintfmt+0x2df>
  8010d1:	eb 37                	jmp    80110a <vprintfmt+0x335>
  8010d3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%rbp)
  8010d7:	74 1e                	je     8010f7 <vprintfmt+0x322>
  8010d9:	83 fb 1f             	cmp    $0x1f,%ebx
  8010dc:	7e 05                	jle    8010e3 <vprintfmt+0x30e>
  8010de:	83 fb 7e             	cmp    $0x7e,%ebx
  8010e1:	7e 14                	jle    8010f7 <vprintfmt+0x322>
  8010e3:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8010e7:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8010eb:	48 89 d6             	mov    %rdx,%rsi
  8010ee:	bf 3f 00 00 00       	mov    $0x3f,%edi
  8010f3:	ff d0                	callq  *%rax
  8010f5:	eb 0f                	jmp    801106 <vprintfmt+0x331>
  8010f7:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8010fb:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8010ff:	48 89 d6             	mov    %rdx,%rsi
  801102:	89 df                	mov    %ebx,%edi
  801104:	ff d0                	callq  *%rax
  801106:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  80110a:	4c 89 e0             	mov    %r12,%rax
  80110d:	4c 8d 60 01          	lea    0x1(%rax),%r12
  801111:	0f b6 00             	movzbl (%rax),%eax
  801114:	0f be d8             	movsbl %al,%ebx
  801117:	85 db                	test   %ebx,%ebx
  801119:	74 10                	je     80112b <vprintfmt+0x356>
  80111b:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  80111f:	78 b2                	js     8010d3 <vprintfmt+0x2fe>
  801121:	83 6d d8 01          	subl   $0x1,-0x28(%rbp)
  801125:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  801129:	79 a8                	jns    8010d3 <vprintfmt+0x2fe>
  80112b:	eb 16                	jmp    801143 <vprintfmt+0x36e>
  80112d:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801131:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801135:	48 89 d6             	mov    %rdx,%rsi
  801138:	bf 20 00 00 00       	mov    $0x20,%edi
  80113d:	ff d0                	callq  *%rax
  80113f:	83 6d dc 01          	subl   $0x1,-0x24(%rbp)
  801143:	83 7d dc 00          	cmpl   $0x0,-0x24(%rbp)
  801147:	7f e4                	jg     80112d <vprintfmt+0x358>
  801149:	e9 90 01 00 00       	jmpq   8012de <vprintfmt+0x509>
  80114e:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  801152:	be 03 00 00 00       	mov    $0x3,%esi
  801157:	48 89 c7             	mov    %rax,%rdi
  80115a:	48 b8 c5 0c 80 00 00 	movabs $0x800cc5,%rax
  801161:	00 00 00 
  801164:	ff d0                	callq  *%rax
  801166:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80116a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80116e:	48 85 c0             	test   %rax,%rax
  801171:	79 1d                	jns    801190 <vprintfmt+0x3bb>
  801173:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801177:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  80117b:	48 89 d6             	mov    %rdx,%rsi
  80117e:	bf 2d 00 00 00       	mov    $0x2d,%edi
  801183:	ff d0                	callq  *%rax
  801185:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801189:	48 f7 d8             	neg    %rax
  80118c:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801190:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  801197:	e9 d5 00 00 00       	jmpq   801271 <vprintfmt+0x49c>
  80119c:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  8011a0:	be 03 00 00 00       	mov    $0x3,%esi
  8011a5:	48 89 c7             	mov    %rax,%rdi
  8011a8:	48 b8 b5 0b 80 00 00 	movabs $0x800bb5,%rax
  8011af:	00 00 00 
  8011b2:	ff d0                	callq  *%rax
  8011b4:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8011b8:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%rbp)
  8011bf:	e9 ad 00 00 00       	jmpq   801271 <vprintfmt+0x49c>
  8011c4:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  8011c8:	be 03 00 00 00       	mov    $0x3,%esi
  8011cd:	48 89 c7             	mov    %rax,%rdi
  8011d0:	48 b8 b5 0b 80 00 00 	movabs $0x800bb5,%rax
  8011d7:	00 00 00 
  8011da:	ff d0                	callq  *%rax
  8011dc:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8011e0:	c7 45 e4 08 00 00 00 	movl   $0x8,-0x1c(%rbp)
  8011e7:	e9 85 00 00 00       	jmpq   801271 <vprintfmt+0x49c>
  8011ec:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8011f0:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8011f4:	48 89 d6             	mov    %rdx,%rsi
  8011f7:	bf 30 00 00 00       	mov    $0x30,%edi
  8011fc:	ff d0                	callq  *%rax
  8011fe:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  801202:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801206:	48 89 d6             	mov    %rdx,%rsi
  801209:	bf 78 00 00 00       	mov    $0x78,%edi
  80120e:	ff d0                	callq  *%rax
  801210:	8b 45 b8             	mov    -0x48(%rbp),%eax
  801213:	83 f8 30             	cmp    $0x30,%eax
  801216:	73 17                	jae    80122f <vprintfmt+0x45a>
  801218:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80121c:	8b 45 b8             	mov    -0x48(%rbp),%eax
  80121f:	89 c0                	mov    %eax,%eax
  801221:	48 01 d0             	add    %rdx,%rax
  801224:	8b 55 b8             	mov    -0x48(%rbp),%edx
  801227:	83 c2 08             	add    $0x8,%edx
  80122a:	89 55 b8             	mov    %edx,-0x48(%rbp)
  80122d:	eb 0f                	jmp    80123e <vprintfmt+0x469>
  80122f:	48 8b 55 c0          	mov    -0x40(%rbp),%rdx
  801233:	48 89 d0             	mov    %rdx,%rax
  801236:	48 83 c2 08          	add    $0x8,%rdx
  80123a:	48 89 55 c0          	mov    %rdx,-0x40(%rbp)
  80123e:	48 8b 00             	mov    (%rax),%rax
  801241:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801245:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  80124c:	eb 23                	jmp    801271 <vprintfmt+0x49c>
  80124e:	48 8d 45 b8          	lea    -0x48(%rbp),%rax
  801252:	be 03 00 00 00       	mov    $0x3,%esi
  801257:	48 89 c7             	mov    %rax,%rdi
  80125a:	48 b8 b5 0b 80 00 00 	movabs $0x800bb5,%rax
  801261:	00 00 00 
  801264:	ff d0                	callq  *%rax
  801266:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  80126a:	c7 45 e4 10 00 00 00 	movl   $0x10,-0x1c(%rbp)
  801271:	44 0f be 45 d3       	movsbl -0x2d(%rbp),%r8d
  801276:	8b 4d e4             	mov    -0x1c(%rbp),%ecx
  801279:	8b 7d dc             	mov    -0x24(%rbp),%edi
  80127c:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801280:	48 8b 75 a0          	mov    -0x60(%rbp),%rsi
  801284:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  801288:	45 89 c1             	mov    %r8d,%r9d
  80128b:	41 89 f8             	mov    %edi,%r8d
  80128e:	48 89 c7             	mov    %rax,%rdi
  801291:	48 b8 fa 0a 80 00 00 	movabs $0x800afa,%rax
  801298:	00 00 00 
  80129b:	ff d0                	callq  *%rax
  80129d:	eb 3f                	jmp    8012de <vprintfmt+0x509>
  80129f:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8012a3:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8012a7:	48 89 d6             	mov    %rdx,%rsi
  8012aa:	89 df                	mov    %ebx,%edi
  8012ac:	ff d0                	callq  *%rax
  8012ae:	eb 2e                	jmp    8012de <vprintfmt+0x509>
  8012b0:	48 8b 55 a0          	mov    -0x60(%rbp),%rdx
  8012b4:	48 8b 45 a8          	mov    -0x58(%rbp),%rax
  8012b8:	48 89 d6             	mov    %rdx,%rsi
  8012bb:	bf 25 00 00 00       	mov    $0x25,%edi
  8012c0:	ff d0                	callq  *%rax
  8012c2:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8012c7:	eb 05                	jmp    8012ce <vprintfmt+0x4f9>
  8012c9:	48 83 6d 98 01       	subq   $0x1,-0x68(%rbp)
  8012ce:	48 8b 45 98          	mov    -0x68(%rbp),%rax
  8012d2:	48 83 e8 01          	sub    $0x1,%rax
  8012d6:	0f b6 00             	movzbl (%rax),%eax
  8012d9:	3c 25                	cmp    $0x25,%al
  8012db:	75 ec                	jne    8012c9 <vprintfmt+0x4f4>
  8012dd:	90                   	nop
  8012de:	90                   	nop
  8012df:	e9 43 fb ff ff       	jmpq   800e27 <vprintfmt+0x52>
  8012e4:	48 83 c4 60          	add    $0x60,%rsp
  8012e8:	5b                   	pop    %rbx
  8012e9:	41 5c                	pop    %r12
  8012eb:	5d                   	pop    %rbp
  8012ec:	c3                   	retq   

00000000008012ed <printfmt>:
  8012ed:	55                   	push   %rbp
  8012ee:	48 89 e5             	mov    %rsp,%rbp
  8012f1:	48 81 ec f0 00 00 00 	sub    $0xf0,%rsp
  8012f8:	48 89 bd 28 ff ff ff 	mov    %rdi,-0xd8(%rbp)
  8012ff:	48 89 b5 20 ff ff ff 	mov    %rsi,-0xe0(%rbp)
  801306:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  80130d:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  801314:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  80131b:	84 c0                	test   %al,%al
  80131d:	74 20                	je     80133f <printfmt+0x52>
  80131f:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  801323:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  801327:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  80132b:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  80132f:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  801333:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  801337:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  80133b:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  80133f:	48 89 95 18 ff ff ff 	mov    %rdx,-0xe8(%rbp)
  801346:	c7 85 38 ff ff ff 18 	movl   $0x18,-0xc8(%rbp)
  80134d:	00 00 00 
  801350:	c7 85 3c ff ff ff 30 	movl   $0x30,-0xc4(%rbp)
  801357:	00 00 00 
  80135a:	48 8d 45 10          	lea    0x10(%rbp),%rax
  80135e:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  801365:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  80136c:	48 89 85 48 ff ff ff 	mov    %rax,-0xb8(%rbp)
  801373:	48 8d 8d 38 ff ff ff 	lea    -0xc8(%rbp),%rcx
  80137a:	48 8b 95 18 ff ff ff 	mov    -0xe8(%rbp),%rdx
  801381:	48 8b b5 20 ff ff ff 	mov    -0xe0(%rbp),%rsi
  801388:	48 8b 85 28 ff ff ff 	mov    -0xd8(%rbp),%rax
  80138f:	48 89 c7             	mov    %rax,%rdi
  801392:	48 b8 d5 0d 80 00 00 	movabs $0x800dd5,%rax
  801399:	00 00 00 
  80139c:	ff d0                	callq  *%rax
  80139e:	c9                   	leaveq 
  80139f:	c3                   	retq   

00000000008013a0 <sprintputch>:
  8013a0:	55                   	push   %rbp
  8013a1:	48 89 e5             	mov    %rsp,%rbp
  8013a4:	48 83 ec 10          	sub    $0x10,%rsp
  8013a8:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8013ab:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8013af:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8013b3:	8b 40 10             	mov    0x10(%rax),%eax
  8013b6:	8d 50 01             	lea    0x1(%rax),%edx
  8013b9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8013bd:	89 50 10             	mov    %edx,0x10(%rax)
  8013c0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8013c4:	48 8b 10             	mov    (%rax),%rdx
  8013c7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8013cb:	48 8b 40 08          	mov    0x8(%rax),%rax
  8013cf:	48 39 c2             	cmp    %rax,%rdx
  8013d2:	73 17                	jae    8013eb <sprintputch+0x4b>
  8013d4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8013d8:	48 8b 00             	mov    (%rax),%rax
  8013db:	48 8d 48 01          	lea    0x1(%rax),%rcx
  8013df:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8013e3:	48 89 0a             	mov    %rcx,(%rdx)
  8013e6:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8013e9:	88 10                	mov    %dl,(%rax)
  8013eb:	c9                   	leaveq 
  8013ec:	c3                   	retq   

00000000008013ed <vsnprintf>:
  8013ed:	55                   	push   %rbp
  8013ee:	48 89 e5             	mov    %rsp,%rbp
  8013f1:	48 83 ec 50          	sub    $0x50,%rsp
  8013f5:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  8013f9:	89 75 c4             	mov    %esi,-0x3c(%rbp)
  8013fc:	48 89 55 b8          	mov    %rdx,-0x48(%rbp)
  801400:	48 89 4d b0          	mov    %rcx,-0x50(%rbp)
  801404:	48 8d 45 e8          	lea    -0x18(%rbp),%rax
  801408:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  80140c:	48 8b 0a             	mov    (%rdx),%rcx
  80140f:	48 89 08             	mov    %rcx,(%rax)
  801412:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  801416:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80141a:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80141e:	48 89 50 10          	mov    %rdx,0x10(%rax)
  801422:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  801426:	48 89 45 d0          	mov    %rax,-0x30(%rbp)
  80142a:	8b 45 c4             	mov    -0x3c(%rbp),%eax
  80142d:	48 98                	cltq   
  80142f:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  801433:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  801437:	48 01 d0             	add    %rdx,%rax
  80143a:	48 89 45 d8          	mov    %rax,-0x28(%rbp)
  80143e:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%rbp)
  801445:	48 83 7d c8 00       	cmpq   $0x0,-0x38(%rbp)
  80144a:	74 06                	je     801452 <vsnprintf+0x65>
  80144c:	83 7d c4 00          	cmpl   $0x0,-0x3c(%rbp)
  801450:	7f 07                	jg     801459 <vsnprintf+0x6c>
  801452:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  801457:	eb 2f                	jmp    801488 <vsnprintf+0x9b>
  801459:	48 8d 4d e8          	lea    -0x18(%rbp),%rcx
  80145d:	48 8b 55 b8          	mov    -0x48(%rbp),%rdx
  801461:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  801465:	48 89 c6             	mov    %rax,%rsi
  801468:	48 bf a0 13 80 00 00 	movabs $0x8013a0,%rdi
  80146f:	00 00 00 
  801472:	48 b8 d5 0d 80 00 00 	movabs $0x800dd5,%rax
  801479:	00 00 00 
  80147c:	ff d0                	callq  *%rax
  80147e:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801482:	c6 00 00             	movb   $0x0,(%rax)
  801485:	8b 45 e0             	mov    -0x20(%rbp),%eax
  801488:	c9                   	leaveq 
  801489:	c3                   	retq   

000000000080148a <snprintf>:
  80148a:	55                   	push   %rbp
  80148b:	48 89 e5             	mov    %rsp,%rbp
  80148e:	48 81 ec 10 01 00 00 	sub    $0x110,%rsp
  801495:	48 89 bd 08 ff ff ff 	mov    %rdi,-0xf8(%rbp)
  80149c:	89 b5 04 ff ff ff    	mov    %esi,-0xfc(%rbp)
  8014a2:	48 89 8d 68 ff ff ff 	mov    %rcx,-0x98(%rbp)
  8014a9:	4c 89 85 70 ff ff ff 	mov    %r8,-0x90(%rbp)
  8014b0:	4c 89 8d 78 ff ff ff 	mov    %r9,-0x88(%rbp)
  8014b7:	84 c0                	test   %al,%al
  8014b9:	74 20                	je     8014db <snprintf+0x51>
  8014bb:	0f 29 45 80          	movaps %xmm0,-0x80(%rbp)
  8014bf:	0f 29 4d 90          	movaps %xmm1,-0x70(%rbp)
  8014c3:	0f 29 55 a0          	movaps %xmm2,-0x60(%rbp)
  8014c7:	0f 29 5d b0          	movaps %xmm3,-0x50(%rbp)
  8014cb:	0f 29 65 c0          	movaps %xmm4,-0x40(%rbp)
  8014cf:	0f 29 6d d0          	movaps %xmm5,-0x30(%rbp)
  8014d3:	0f 29 75 e0          	movaps %xmm6,-0x20(%rbp)
  8014d7:	0f 29 7d f0          	movaps %xmm7,-0x10(%rbp)
  8014db:	48 89 95 f8 fe ff ff 	mov    %rdx,-0x108(%rbp)
  8014e2:	c7 85 30 ff ff ff 18 	movl   $0x18,-0xd0(%rbp)
  8014e9:	00 00 00 
  8014ec:	c7 85 34 ff ff ff 30 	movl   $0x30,-0xcc(%rbp)
  8014f3:	00 00 00 
  8014f6:	48 8d 45 10          	lea    0x10(%rbp),%rax
  8014fa:	48 89 85 38 ff ff ff 	mov    %rax,-0xc8(%rbp)
  801501:	48 8d 85 50 ff ff ff 	lea    -0xb0(%rbp),%rax
  801508:	48 89 85 40 ff ff ff 	mov    %rax,-0xc0(%rbp)
  80150f:	48 8d 85 18 ff ff ff 	lea    -0xe8(%rbp),%rax
  801516:	48 8d 95 30 ff ff ff 	lea    -0xd0(%rbp),%rdx
  80151d:	48 8b 0a             	mov    (%rdx),%rcx
  801520:	48 89 08             	mov    %rcx,(%rax)
  801523:	48 8b 4a 08          	mov    0x8(%rdx),%rcx
  801527:	48 89 48 08          	mov    %rcx,0x8(%rax)
  80152b:	48 8b 52 10          	mov    0x10(%rdx),%rdx
  80152f:	48 89 50 10          	mov    %rdx,0x10(%rax)
  801533:	48 8d 8d 18 ff ff ff 	lea    -0xe8(%rbp),%rcx
  80153a:	48 8b 95 f8 fe ff ff 	mov    -0x108(%rbp),%rdx
  801541:	8b b5 04 ff ff ff    	mov    -0xfc(%rbp),%esi
  801547:	48 8b 85 08 ff ff ff 	mov    -0xf8(%rbp),%rax
  80154e:	48 89 c7             	mov    %rax,%rdi
  801551:	48 b8 ed 13 80 00 00 	movabs $0x8013ed,%rax
  801558:	00 00 00 
  80155b:	ff d0                	callq  *%rax
  80155d:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%rbp)
  801563:	8b 85 4c ff ff ff    	mov    -0xb4(%rbp),%eax
  801569:	c9                   	leaveq 
  80156a:	c3                   	retq   

000000000080156b <strlen>:
  80156b:	55                   	push   %rbp
  80156c:	48 89 e5             	mov    %rsp,%rbp
  80156f:	48 83 ec 18          	sub    $0x18,%rsp
  801573:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801577:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  80157e:	eb 09                	jmp    801589 <strlen+0x1e>
  801580:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  801584:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  801589:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80158d:	0f b6 00             	movzbl (%rax),%eax
  801590:	84 c0                	test   %al,%al
  801592:	75 ec                	jne    801580 <strlen+0x15>
  801594:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801597:	c9                   	leaveq 
  801598:	c3                   	retq   

0000000000801599 <strnlen>:
  801599:	55                   	push   %rbp
  80159a:	48 89 e5             	mov    %rsp,%rbp
  80159d:	48 83 ec 20          	sub    $0x20,%rsp
  8015a1:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8015a5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8015a9:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8015b0:	eb 0e                	jmp    8015c0 <strnlen+0x27>
  8015b2:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8015b6:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  8015bb:	48 83 6d e0 01       	subq   $0x1,-0x20(%rbp)
  8015c0:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  8015c5:	74 0b                	je     8015d2 <strnlen+0x39>
  8015c7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8015cb:	0f b6 00             	movzbl (%rax),%eax
  8015ce:	84 c0                	test   %al,%al
  8015d0:	75 e0                	jne    8015b2 <strnlen+0x19>
  8015d2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8015d5:	c9                   	leaveq 
  8015d6:	c3                   	retq   

00000000008015d7 <strcpy>:
  8015d7:	55                   	push   %rbp
  8015d8:	48 89 e5             	mov    %rsp,%rbp
  8015db:	48 83 ec 20          	sub    $0x20,%rsp
  8015df:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8015e3:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8015e7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8015eb:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8015ef:	90                   	nop
  8015f0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8015f4:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8015f8:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8015fc:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  801600:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  801604:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  801608:	0f b6 12             	movzbl (%rdx),%edx
  80160b:	88 10                	mov    %dl,(%rax)
  80160d:	0f b6 00             	movzbl (%rax),%eax
  801610:	84 c0                	test   %al,%al
  801612:	75 dc                	jne    8015f0 <strcpy+0x19>
  801614:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801618:	c9                   	leaveq 
  801619:	c3                   	retq   

000000000080161a <strcat>:
  80161a:	55                   	push   %rbp
  80161b:	48 89 e5             	mov    %rsp,%rbp
  80161e:	48 83 ec 20          	sub    $0x20,%rsp
  801622:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801626:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80162a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80162e:	48 89 c7             	mov    %rax,%rdi
  801631:	48 b8 6b 15 80 00 00 	movabs $0x80156b,%rax
  801638:	00 00 00 
  80163b:	ff d0                	callq  *%rax
  80163d:	89 45 fc             	mov    %eax,-0x4(%rbp)
  801640:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801643:	48 63 d0             	movslq %eax,%rdx
  801646:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80164a:	48 01 c2             	add    %rax,%rdx
  80164d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  801651:	48 89 c6             	mov    %rax,%rsi
  801654:	48 89 d7             	mov    %rdx,%rdi
  801657:	48 b8 d7 15 80 00 00 	movabs $0x8015d7,%rax
  80165e:	00 00 00 
  801661:	ff d0                	callq  *%rax
  801663:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801667:	c9                   	leaveq 
  801668:	c3                   	retq   

0000000000801669 <strncpy>:
  801669:	55                   	push   %rbp
  80166a:	48 89 e5             	mov    %rsp,%rbp
  80166d:	48 83 ec 28          	sub    $0x28,%rsp
  801671:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801675:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801679:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80167d:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801681:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801685:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  80168c:	00 
  80168d:	eb 2a                	jmp    8016b9 <strncpy+0x50>
  80168f:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801693:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801697:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80169b:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  80169f:	0f b6 12             	movzbl (%rdx),%edx
  8016a2:	88 10                	mov    %dl,(%rax)
  8016a4:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8016a8:	0f b6 00             	movzbl (%rax),%eax
  8016ab:	84 c0                	test   %al,%al
  8016ad:	74 05                	je     8016b4 <strncpy+0x4b>
  8016af:	48 83 45 e0 01       	addq   $0x1,-0x20(%rbp)
  8016b4:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8016b9:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8016bd:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  8016c1:	72 cc                	jb     80168f <strncpy+0x26>
  8016c3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8016c7:	c9                   	leaveq 
  8016c8:	c3                   	retq   

00000000008016c9 <strlcpy>:
  8016c9:	55                   	push   %rbp
  8016ca:	48 89 e5             	mov    %rsp,%rbp
  8016cd:	48 83 ec 28          	sub    $0x28,%rsp
  8016d1:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8016d5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8016d9:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8016dd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8016e1:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8016e5:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8016ea:	74 3d                	je     801729 <strlcpy+0x60>
  8016ec:	eb 1d                	jmp    80170b <strlcpy+0x42>
  8016ee:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8016f2:	48 8d 50 01          	lea    0x1(%rax),%rdx
  8016f6:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8016fa:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  8016fe:	48 8d 4a 01          	lea    0x1(%rdx),%rcx
  801702:	48 89 4d e0          	mov    %rcx,-0x20(%rbp)
  801706:	0f b6 12             	movzbl (%rdx),%edx
  801709:	88 10                	mov    %dl,(%rax)
  80170b:	48 83 6d d8 01       	subq   $0x1,-0x28(%rbp)
  801710:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  801715:	74 0b                	je     801722 <strlcpy+0x59>
  801717:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80171b:	0f b6 00             	movzbl (%rax),%eax
  80171e:	84 c0                	test   %al,%al
  801720:	75 cc                	jne    8016ee <strlcpy+0x25>
  801722:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801726:	c6 00 00             	movb   $0x0,(%rax)
  801729:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  80172d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801731:	48 29 c2             	sub    %rax,%rdx
  801734:	48 89 d0             	mov    %rdx,%rax
  801737:	c9                   	leaveq 
  801738:	c3                   	retq   

0000000000801739 <strcmp>:
  801739:	55                   	push   %rbp
  80173a:	48 89 e5             	mov    %rsp,%rbp
  80173d:	48 83 ec 10          	sub    $0x10,%rsp
  801741:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801745:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801749:	eb 0a                	jmp    801755 <strcmp+0x1c>
  80174b:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801750:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  801755:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801759:	0f b6 00             	movzbl (%rax),%eax
  80175c:	84 c0                	test   %al,%al
  80175e:	74 12                	je     801772 <strcmp+0x39>
  801760:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801764:	0f b6 10             	movzbl (%rax),%edx
  801767:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80176b:	0f b6 00             	movzbl (%rax),%eax
  80176e:	38 c2                	cmp    %al,%dl
  801770:	74 d9                	je     80174b <strcmp+0x12>
  801772:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801776:	0f b6 00             	movzbl (%rax),%eax
  801779:	0f b6 d0             	movzbl %al,%edx
  80177c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801780:	0f b6 00             	movzbl (%rax),%eax
  801783:	0f b6 c0             	movzbl %al,%eax
  801786:	29 c2                	sub    %eax,%edx
  801788:	89 d0                	mov    %edx,%eax
  80178a:	c9                   	leaveq 
  80178b:	c3                   	retq   

000000000080178c <strncmp>:
  80178c:	55                   	push   %rbp
  80178d:	48 89 e5             	mov    %rsp,%rbp
  801790:	48 83 ec 18          	sub    $0x18,%rsp
  801794:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801798:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80179c:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8017a0:	eb 0f                	jmp    8017b1 <strncmp+0x25>
  8017a2:	48 83 6d e8 01       	subq   $0x1,-0x18(%rbp)
  8017a7:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8017ac:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  8017b1:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8017b6:	74 1d                	je     8017d5 <strncmp+0x49>
  8017b8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017bc:	0f b6 00             	movzbl (%rax),%eax
  8017bf:	84 c0                	test   %al,%al
  8017c1:	74 12                	je     8017d5 <strncmp+0x49>
  8017c3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017c7:	0f b6 10             	movzbl (%rax),%edx
  8017ca:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8017ce:	0f b6 00             	movzbl (%rax),%eax
  8017d1:	38 c2                	cmp    %al,%dl
  8017d3:	74 cd                	je     8017a2 <strncmp+0x16>
  8017d5:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  8017da:	75 07                	jne    8017e3 <strncmp+0x57>
  8017dc:	b8 00 00 00 00       	mov    $0x0,%eax
  8017e1:	eb 18                	jmp    8017fb <strncmp+0x6f>
  8017e3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8017e7:	0f b6 00             	movzbl (%rax),%eax
  8017ea:	0f b6 d0             	movzbl %al,%edx
  8017ed:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8017f1:	0f b6 00             	movzbl (%rax),%eax
  8017f4:	0f b6 c0             	movzbl %al,%eax
  8017f7:	29 c2                	sub    %eax,%edx
  8017f9:	89 d0                	mov    %edx,%eax
  8017fb:	c9                   	leaveq 
  8017fc:	c3                   	retq   

00000000008017fd <strchr>:
  8017fd:	55                   	push   %rbp
  8017fe:	48 89 e5             	mov    %rsp,%rbp
  801801:	48 83 ec 0c          	sub    $0xc,%rsp
  801805:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801809:	89 f0                	mov    %esi,%eax
  80180b:	88 45 f4             	mov    %al,-0xc(%rbp)
  80180e:	eb 17                	jmp    801827 <strchr+0x2a>
  801810:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801814:	0f b6 00             	movzbl (%rax),%eax
  801817:	3a 45 f4             	cmp    -0xc(%rbp),%al
  80181a:	75 06                	jne    801822 <strchr+0x25>
  80181c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801820:	eb 15                	jmp    801837 <strchr+0x3a>
  801822:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801827:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80182b:	0f b6 00             	movzbl (%rax),%eax
  80182e:	84 c0                	test   %al,%al
  801830:	75 de                	jne    801810 <strchr+0x13>
  801832:	b8 00 00 00 00       	mov    $0x0,%eax
  801837:	c9                   	leaveq 
  801838:	c3                   	retq   

0000000000801839 <strfind>:
  801839:	55                   	push   %rbp
  80183a:	48 89 e5             	mov    %rsp,%rbp
  80183d:	48 83 ec 0c          	sub    $0xc,%rsp
  801841:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801845:	89 f0                	mov    %esi,%eax
  801847:	88 45 f4             	mov    %al,-0xc(%rbp)
  80184a:	eb 13                	jmp    80185f <strfind+0x26>
  80184c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801850:	0f b6 00             	movzbl (%rax),%eax
  801853:	3a 45 f4             	cmp    -0xc(%rbp),%al
  801856:	75 02                	jne    80185a <strfind+0x21>
  801858:	eb 10                	jmp    80186a <strfind+0x31>
  80185a:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  80185f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801863:	0f b6 00             	movzbl (%rax),%eax
  801866:	84 c0                	test   %al,%al
  801868:	75 e2                	jne    80184c <strfind+0x13>
  80186a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80186e:	c9                   	leaveq 
  80186f:	c3                   	retq   

0000000000801870 <memset>:
  801870:	55                   	push   %rbp
  801871:	48 89 e5             	mov    %rsp,%rbp
  801874:	48 83 ec 18          	sub    $0x18,%rsp
  801878:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80187c:	89 75 f4             	mov    %esi,-0xc(%rbp)
  80187f:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801883:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  801888:	75 06                	jne    801890 <memset+0x20>
  80188a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80188e:	eb 69                	jmp    8018f9 <memset+0x89>
  801890:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801894:	83 e0 03             	and    $0x3,%eax
  801897:	48 85 c0             	test   %rax,%rax
  80189a:	75 48                	jne    8018e4 <memset+0x74>
  80189c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8018a0:	83 e0 03             	and    $0x3,%eax
  8018a3:	48 85 c0             	test   %rax,%rax
  8018a6:	75 3c                	jne    8018e4 <memset+0x74>
  8018a8:	81 65 f4 ff 00 00 00 	andl   $0xff,-0xc(%rbp)
  8018af:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8018b2:	c1 e0 18             	shl    $0x18,%eax
  8018b5:	89 c2                	mov    %eax,%edx
  8018b7:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8018ba:	c1 e0 10             	shl    $0x10,%eax
  8018bd:	09 c2                	or     %eax,%edx
  8018bf:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8018c2:	c1 e0 08             	shl    $0x8,%eax
  8018c5:	09 d0                	or     %edx,%eax
  8018c7:	09 45 f4             	or     %eax,-0xc(%rbp)
  8018ca:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8018ce:	48 c1 e8 02          	shr    $0x2,%rax
  8018d2:	48 89 c1             	mov    %rax,%rcx
  8018d5:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8018d9:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8018dc:	48 89 d7             	mov    %rdx,%rdi
  8018df:	fc                   	cld    
  8018e0:	f3 ab                	rep stos %eax,%es:(%rdi)
  8018e2:	eb 11                	jmp    8018f5 <memset+0x85>
  8018e4:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8018e8:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8018eb:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8018ef:	48 89 d7             	mov    %rdx,%rdi
  8018f2:	fc                   	cld    
  8018f3:	f3 aa                	rep stos %al,%es:(%rdi)
  8018f5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8018f9:	c9                   	leaveq 
  8018fa:	c3                   	retq   

00000000008018fb <memmove>:
  8018fb:	55                   	push   %rbp
  8018fc:	48 89 e5             	mov    %rsp,%rbp
  8018ff:	48 83 ec 28          	sub    $0x28,%rsp
  801903:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801907:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80190b:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  80190f:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  801913:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801917:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80191b:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80191f:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801923:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  801927:	0f 83 88 00 00 00    	jae    8019b5 <memmove+0xba>
  80192d:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801931:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  801935:	48 01 d0             	add    %rdx,%rax
  801938:	48 3b 45 f0          	cmp    -0x10(%rbp),%rax
  80193c:	76 77                	jbe    8019b5 <memmove+0xba>
  80193e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801942:	48 01 45 f8          	add    %rax,-0x8(%rbp)
  801946:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80194a:	48 01 45 f0          	add    %rax,-0x10(%rbp)
  80194e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801952:	83 e0 03             	and    $0x3,%eax
  801955:	48 85 c0             	test   %rax,%rax
  801958:	75 3b                	jne    801995 <memmove+0x9a>
  80195a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80195e:	83 e0 03             	and    $0x3,%eax
  801961:	48 85 c0             	test   %rax,%rax
  801964:	75 2f                	jne    801995 <memmove+0x9a>
  801966:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80196a:	83 e0 03             	and    $0x3,%eax
  80196d:	48 85 c0             	test   %rax,%rax
  801970:	75 23                	jne    801995 <memmove+0x9a>
  801972:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801976:	48 83 e8 04          	sub    $0x4,%rax
  80197a:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  80197e:	48 83 ea 04          	sub    $0x4,%rdx
  801982:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  801986:	48 c1 e9 02          	shr    $0x2,%rcx
  80198a:	48 89 c7             	mov    %rax,%rdi
  80198d:	48 89 d6             	mov    %rdx,%rsi
  801990:	fd                   	std    
  801991:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  801993:	eb 1d                	jmp    8019b2 <memmove+0xb7>
  801995:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801999:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  80199d:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8019a1:	48 8d 70 ff          	lea    -0x1(%rax),%rsi
  8019a5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019a9:	48 89 d7             	mov    %rdx,%rdi
  8019ac:	48 89 c1             	mov    %rax,%rcx
  8019af:	fd                   	std    
  8019b0:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  8019b2:	fc                   	cld    
  8019b3:	eb 57                	jmp    801a0c <memmove+0x111>
  8019b5:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8019b9:	83 e0 03             	and    $0x3,%eax
  8019bc:	48 85 c0             	test   %rax,%rax
  8019bf:	75 36                	jne    8019f7 <memmove+0xfc>
  8019c1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8019c5:	83 e0 03             	and    $0x3,%eax
  8019c8:	48 85 c0             	test   %rax,%rax
  8019cb:	75 2a                	jne    8019f7 <memmove+0xfc>
  8019cd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019d1:	83 e0 03             	and    $0x3,%eax
  8019d4:	48 85 c0             	test   %rax,%rax
  8019d7:	75 1e                	jne    8019f7 <memmove+0xfc>
  8019d9:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8019dd:	48 c1 e8 02          	shr    $0x2,%rax
  8019e1:	48 89 c1             	mov    %rax,%rcx
  8019e4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8019e8:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8019ec:	48 89 c7             	mov    %rax,%rdi
  8019ef:	48 89 d6             	mov    %rdx,%rsi
  8019f2:	fc                   	cld    
  8019f3:	f3 a5                	rep movsl %ds:(%rsi),%es:(%rdi)
  8019f5:	eb 15                	jmp    801a0c <memmove+0x111>
  8019f7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8019fb:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8019ff:	48 8b 4d d8          	mov    -0x28(%rbp),%rcx
  801a03:	48 89 c7             	mov    %rax,%rdi
  801a06:	48 89 d6             	mov    %rdx,%rsi
  801a09:	fc                   	cld    
  801a0a:	f3 a4                	rep movsb %ds:(%rsi),%es:(%rdi)
  801a0c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801a10:	c9                   	leaveq 
  801a11:	c3                   	retq   

0000000000801a12 <memcpy>:
  801a12:	55                   	push   %rbp
  801a13:	48 89 e5             	mov    %rsp,%rbp
  801a16:	48 83 ec 18          	sub    $0x18,%rsp
  801a1a:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801a1e:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801a22:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  801a26:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801a2a:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  801a2e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801a32:	48 89 ce             	mov    %rcx,%rsi
  801a35:	48 89 c7             	mov    %rax,%rdi
  801a38:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  801a3f:	00 00 00 
  801a42:	ff d0                	callq  *%rax
  801a44:	c9                   	leaveq 
  801a45:	c3                   	retq   

0000000000801a46 <memcmp>:
  801a46:	55                   	push   %rbp
  801a47:	48 89 e5             	mov    %rsp,%rbp
  801a4a:	48 83 ec 28          	sub    $0x28,%rsp
  801a4e:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801a52:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  801a56:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801a5a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801a5e:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801a62:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  801a66:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801a6a:	eb 36                	jmp    801aa2 <memcmp+0x5c>
  801a6c:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801a70:	0f b6 10             	movzbl (%rax),%edx
  801a73:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801a77:	0f b6 00             	movzbl (%rax),%eax
  801a7a:	38 c2                	cmp    %al,%dl
  801a7c:	74 1a                	je     801a98 <memcmp+0x52>
  801a7e:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801a82:	0f b6 00             	movzbl (%rax),%eax
  801a85:	0f b6 d0             	movzbl %al,%edx
  801a88:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801a8c:	0f b6 00             	movzbl (%rax),%eax
  801a8f:	0f b6 c0             	movzbl %al,%eax
  801a92:	29 c2                	sub    %eax,%edx
  801a94:	89 d0                	mov    %edx,%eax
  801a96:	eb 20                	jmp    801ab8 <memcmp+0x72>
  801a98:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  801a9d:	48 83 45 f0 01       	addq   $0x1,-0x10(%rbp)
  801aa2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801aa6:	48 8d 50 ff          	lea    -0x1(%rax),%rdx
  801aaa:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801aae:	48 85 c0             	test   %rax,%rax
  801ab1:	75 b9                	jne    801a6c <memcmp+0x26>
  801ab3:	b8 00 00 00 00       	mov    $0x0,%eax
  801ab8:	c9                   	leaveq 
  801ab9:	c3                   	retq   

0000000000801aba <memfind>:
  801aba:	55                   	push   %rbp
  801abb:	48 89 e5             	mov    %rsp,%rbp
  801abe:	48 83 ec 28          	sub    $0x28,%rsp
  801ac2:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  801ac6:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  801ac9:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801acd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801ad1:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801ad5:	48 01 d0             	add    %rdx,%rax
  801ad8:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  801adc:	eb 15                	jmp    801af3 <memfind+0x39>
  801ade:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801ae2:	0f b6 10             	movzbl (%rax),%edx
  801ae5:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  801ae8:	38 c2                	cmp    %al,%dl
  801aea:	75 02                	jne    801aee <memfind+0x34>
  801aec:	eb 0f                	jmp    801afd <memfind+0x43>
  801aee:	48 83 45 e8 01       	addq   $0x1,-0x18(%rbp)
  801af3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801af7:	48 3b 45 f8          	cmp    -0x8(%rbp),%rax
  801afb:	72 e1                	jb     801ade <memfind+0x24>
  801afd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801b01:	c9                   	leaveq 
  801b02:	c3                   	retq   

0000000000801b03 <strtol>:
  801b03:	55                   	push   %rbp
  801b04:	48 89 e5             	mov    %rsp,%rbp
  801b07:	48 83 ec 34          	sub    $0x34,%rsp
  801b0b:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  801b0f:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  801b13:	89 55 cc             	mov    %edx,-0x34(%rbp)
  801b16:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  801b1d:	48 c7 45 f0 00 00 00 	movq   $0x0,-0x10(%rbp)
  801b24:	00 
  801b25:	eb 05                	jmp    801b2c <strtol+0x29>
  801b27:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801b2c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b30:	0f b6 00             	movzbl (%rax),%eax
  801b33:	3c 20                	cmp    $0x20,%al
  801b35:	74 f0                	je     801b27 <strtol+0x24>
  801b37:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b3b:	0f b6 00             	movzbl (%rax),%eax
  801b3e:	3c 09                	cmp    $0x9,%al
  801b40:	74 e5                	je     801b27 <strtol+0x24>
  801b42:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b46:	0f b6 00             	movzbl (%rax),%eax
  801b49:	3c 2b                	cmp    $0x2b,%al
  801b4b:	75 07                	jne    801b54 <strtol+0x51>
  801b4d:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801b52:	eb 17                	jmp    801b6b <strtol+0x68>
  801b54:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b58:	0f b6 00             	movzbl (%rax),%eax
  801b5b:	3c 2d                	cmp    $0x2d,%al
  801b5d:	75 0c                	jne    801b6b <strtol+0x68>
  801b5f:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801b64:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%rbp)
  801b6b:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801b6f:	74 06                	je     801b77 <strtol+0x74>
  801b71:	83 7d cc 10          	cmpl   $0x10,-0x34(%rbp)
  801b75:	75 28                	jne    801b9f <strtol+0x9c>
  801b77:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b7b:	0f b6 00             	movzbl (%rax),%eax
  801b7e:	3c 30                	cmp    $0x30,%al
  801b80:	75 1d                	jne    801b9f <strtol+0x9c>
  801b82:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801b86:	48 83 c0 01          	add    $0x1,%rax
  801b8a:	0f b6 00             	movzbl (%rax),%eax
  801b8d:	3c 78                	cmp    $0x78,%al
  801b8f:	75 0e                	jne    801b9f <strtol+0x9c>
  801b91:	48 83 45 d8 02       	addq   $0x2,-0x28(%rbp)
  801b96:	c7 45 cc 10 00 00 00 	movl   $0x10,-0x34(%rbp)
  801b9d:	eb 2c                	jmp    801bcb <strtol+0xc8>
  801b9f:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801ba3:	75 19                	jne    801bbe <strtol+0xbb>
  801ba5:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801ba9:	0f b6 00             	movzbl (%rax),%eax
  801bac:	3c 30                	cmp    $0x30,%al
  801bae:	75 0e                	jne    801bbe <strtol+0xbb>
  801bb0:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801bb5:	c7 45 cc 08 00 00 00 	movl   $0x8,-0x34(%rbp)
  801bbc:	eb 0d                	jmp    801bcb <strtol+0xc8>
  801bbe:	83 7d cc 00          	cmpl   $0x0,-0x34(%rbp)
  801bc2:	75 07                	jne    801bcb <strtol+0xc8>
  801bc4:	c7 45 cc 0a 00 00 00 	movl   $0xa,-0x34(%rbp)
  801bcb:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801bcf:	0f b6 00             	movzbl (%rax),%eax
  801bd2:	3c 2f                	cmp    $0x2f,%al
  801bd4:	7e 1d                	jle    801bf3 <strtol+0xf0>
  801bd6:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801bda:	0f b6 00             	movzbl (%rax),%eax
  801bdd:	3c 39                	cmp    $0x39,%al
  801bdf:	7f 12                	jg     801bf3 <strtol+0xf0>
  801be1:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801be5:	0f b6 00             	movzbl (%rax),%eax
  801be8:	0f be c0             	movsbl %al,%eax
  801beb:	83 e8 30             	sub    $0x30,%eax
  801bee:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801bf1:	eb 4e                	jmp    801c41 <strtol+0x13e>
  801bf3:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801bf7:	0f b6 00             	movzbl (%rax),%eax
  801bfa:	3c 60                	cmp    $0x60,%al
  801bfc:	7e 1d                	jle    801c1b <strtol+0x118>
  801bfe:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c02:	0f b6 00             	movzbl (%rax),%eax
  801c05:	3c 7a                	cmp    $0x7a,%al
  801c07:	7f 12                	jg     801c1b <strtol+0x118>
  801c09:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c0d:	0f b6 00             	movzbl (%rax),%eax
  801c10:	0f be c0             	movsbl %al,%eax
  801c13:	83 e8 57             	sub    $0x57,%eax
  801c16:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801c19:	eb 26                	jmp    801c41 <strtol+0x13e>
  801c1b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c1f:	0f b6 00             	movzbl (%rax),%eax
  801c22:	3c 40                	cmp    $0x40,%al
  801c24:	7e 48                	jle    801c6e <strtol+0x16b>
  801c26:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c2a:	0f b6 00             	movzbl (%rax),%eax
  801c2d:	3c 5a                	cmp    $0x5a,%al
  801c2f:	7f 3d                	jg     801c6e <strtol+0x16b>
  801c31:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801c35:	0f b6 00             	movzbl (%rax),%eax
  801c38:	0f be c0             	movsbl %al,%eax
  801c3b:	83 e8 37             	sub    $0x37,%eax
  801c3e:	89 45 ec             	mov    %eax,-0x14(%rbp)
  801c41:	8b 45 ec             	mov    -0x14(%rbp),%eax
  801c44:	3b 45 cc             	cmp    -0x34(%rbp),%eax
  801c47:	7c 02                	jl     801c4b <strtol+0x148>
  801c49:	eb 23                	jmp    801c6e <strtol+0x16b>
  801c4b:	48 83 45 d8 01       	addq   $0x1,-0x28(%rbp)
  801c50:	8b 45 cc             	mov    -0x34(%rbp),%eax
  801c53:	48 98                	cltq   
  801c55:	48 0f af 45 f0       	imul   -0x10(%rbp),%rax
  801c5a:	48 89 c2             	mov    %rax,%rdx
  801c5d:	8b 45 ec             	mov    -0x14(%rbp),%eax
  801c60:	48 98                	cltq   
  801c62:	48 01 d0             	add    %rdx,%rax
  801c65:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801c69:	e9 5d ff ff ff       	jmpq   801bcb <strtol+0xc8>
  801c6e:	48 83 7d d0 00       	cmpq   $0x0,-0x30(%rbp)
  801c73:	74 0b                	je     801c80 <strtol+0x17d>
  801c75:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801c79:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  801c7d:	48 89 10             	mov    %rdx,(%rax)
  801c80:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  801c84:	74 09                	je     801c8f <strtol+0x18c>
  801c86:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801c8a:	48 f7 d8             	neg    %rax
  801c8d:	eb 04                	jmp    801c93 <strtol+0x190>
  801c8f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  801c93:	c9                   	leaveq 
  801c94:	c3                   	retq   

0000000000801c95 <strstr>:
  801c95:	55                   	push   %rbp
  801c96:	48 89 e5             	mov    %rsp,%rbp
  801c99:	48 83 ec 30          	sub    $0x30,%rsp
  801c9d:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  801ca1:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  801ca5:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801ca9:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801cad:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801cb1:	0f b6 00             	movzbl (%rax),%eax
  801cb4:	88 45 ff             	mov    %al,-0x1(%rbp)
  801cb7:	80 7d ff 00          	cmpb   $0x0,-0x1(%rbp)
  801cbb:	75 06                	jne    801cc3 <strstr+0x2e>
  801cbd:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801cc1:	eb 6b                	jmp    801d2e <strstr+0x99>
  801cc3:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  801cc7:	48 89 c7             	mov    %rax,%rdi
  801cca:	48 b8 6b 15 80 00 00 	movabs $0x80156b,%rax
  801cd1:	00 00 00 
  801cd4:	ff d0                	callq  *%rax
  801cd6:	48 98                	cltq   
  801cd8:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  801cdc:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801ce0:	48 8d 50 01          	lea    0x1(%rax),%rdx
  801ce4:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  801ce8:	0f b6 00             	movzbl (%rax),%eax
  801ceb:	88 45 ef             	mov    %al,-0x11(%rbp)
  801cee:	80 7d ef 00          	cmpb   $0x0,-0x11(%rbp)
  801cf2:	75 07                	jne    801cfb <strstr+0x66>
  801cf4:	b8 00 00 00 00       	mov    $0x0,%eax
  801cf9:	eb 33                	jmp    801d2e <strstr+0x99>
  801cfb:	0f b6 45 ef          	movzbl -0x11(%rbp),%eax
  801cff:	3a 45 ff             	cmp    -0x1(%rbp),%al
  801d02:	75 d8                	jne    801cdc <strstr+0x47>
  801d04:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801d08:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  801d0c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801d10:	48 89 ce             	mov    %rcx,%rsi
  801d13:	48 89 c7             	mov    %rax,%rdi
  801d16:	48 b8 8c 17 80 00 00 	movabs $0x80178c,%rax
  801d1d:	00 00 00 
  801d20:	ff d0                	callq  *%rax
  801d22:	85 c0                	test   %eax,%eax
  801d24:	75 b6                	jne    801cdc <strstr+0x47>
  801d26:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  801d2a:	48 83 e8 01          	sub    $0x1,%rax
  801d2e:	c9                   	leaveq 
  801d2f:	c3                   	retq   

0000000000801d30 <syscall>:
  801d30:	55                   	push   %rbp
  801d31:	48 89 e5             	mov    %rsp,%rbp
  801d34:	53                   	push   %rbx
  801d35:	48 83 ec 48          	sub    $0x48,%rsp
  801d39:	89 7d dc             	mov    %edi,-0x24(%rbp)
  801d3c:	89 75 d8             	mov    %esi,-0x28(%rbp)
  801d3f:	48 89 55 d0          	mov    %rdx,-0x30(%rbp)
  801d43:	48 89 4d c8          	mov    %rcx,-0x38(%rbp)
  801d47:	4c 89 45 c0          	mov    %r8,-0x40(%rbp)
  801d4b:	4c 89 4d b8          	mov    %r9,-0x48(%rbp)
  801d4f:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801d52:	48 8b 55 d0          	mov    -0x30(%rbp),%rdx
  801d56:	48 8b 4d c8          	mov    -0x38(%rbp),%rcx
  801d5a:	4c 8b 45 c0          	mov    -0x40(%rbp),%r8
  801d5e:	48 8b 7d b8          	mov    -0x48(%rbp),%rdi
  801d62:	48 8b 75 10          	mov    0x10(%rbp),%rsi
  801d66:	4c 89 c3             	mov    %r8,%rbx
  801d69:	cd 30                	int    $0x30
  801d6b:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  801d6f:	83 7d d8 00          	cmpl   $0x0,-0x28(%rbp)
  801d73:	74 3e                	je     801db3 <syscall+0x83>
  801d75:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  801d7a:	7e 37                	jle    801db3 <syscall+0x83>
  801d7c:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  801d80:	8b 45 dc             	mov    -0x24(%rbp),%eax
  801d83:	49 89 d0             	mov    %rdx,%r8
  801d86:	89 c1                	mov    %eax,%ecx
  801d88:	48 ba 48 4e 80 00 00 	movabs $0x804e48,%rdx
  801d8f:	00 00 00 
  801d92:	be 24 00 00 00       	mov    $0x24,%esi
  801d97:	48 bf 65 4e 80 00 00 	movabs $0x804e65,%rdi
  801d9e:	00 00 00 
  801da1:	b8 00 00 00 00       	mov    $0x0,%eax
  801da6:	49 b9 e9 07 80 00 00 	movabs $0x8007e9,%r9
  801dad:	00 00 00 
  801db0:	41 ff d1             	callq  *%r9
  801db3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  801db7:	48 83 c4 48          	add    $0x48,%rsp
  801dbb:	5b                   	pop    %rbx
  801dbc:	5d                   	pop    %rbp
  801dbd:	c3                   	retq   

0000000000801dbe <sys_cputs>:
  801dbe:	55                   	push   %rbp
  801dbf:	48 89 e5             	mov    %rsp,%rbp
  801dc2:	48 83 ec 20          	sub    $0x20,%rsp
  801dc6:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  801dca:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801dce:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  801dd2:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801dd6:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801ddd:	00 
  801dde:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801de4:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801dea:	48 89 d1             	mov    %rdx,%rcx
  801ded:	48 89 c2             	mov    %rax,%rdx
  801df0:	be 00 00 00 00       	mov    $0x0,%esi
  801df5:	bf 00 00 00 00       	mov    $0x0,%edi
  801dfa:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801e01:	00 00 00 
  801e04:	ff d0                	callq  *%rax
  801e06:	c9                   	leaveq 
  801e07:	c3                   	retq   

0000000000801e08 <sys_cgetc>:
  801e08:	55                   	push   %rbp
  801e09:	48 89 e5             	mov    %rsp,%rbp
  801e0c:	48 83 ec 10          	sub    $0x10,%rsp
  801e10:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801e17:	00 
  801e18:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801e1e:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801e24:	b9 00 00 00 00       	mov    $0x0,%ecx
  801e29:	ba 00 00 00 00       	mov    $0x0,%edx
  801e2e:	be 00 00 00 00       	mov    $0x0,%esi
  801e33:	bf 01 00 00 00       	mov    $0x1,%edi
  801e38:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801e3f:	00 00 00 
  801e42:	ff d0                	callq  *%rax
  801e44:	c9                   	leaveq 
  801e45:	c3                   	retq   

0000000000801e46 <sys_env_destroy>:
  801e46:	55                   	push   %rbp
  801e47:	48 89 e5             	mov    %rsp,%rbp
  801e4a:	48 83 ec 10          	sub    $0x10,%rsp
  801e4e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801e51:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801e54:	48 98                	cltq   
  801e56:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801e5d:	00 
  801e5e:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801e64:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801e6a:	b9 00 00 00 00       	mov    $0x0,%ecx
  801e6f:	48 89 c2             	mov    %rax,%rdx
  801e72:	be 01 00 00 00       	mov    $0x1,%esi
  801e77:	bf 03 00 00 00       	mov    $0x3,%edi
  801e7c:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801e83:	00 00 00 
  801e86:	ff d0                	callq  *%rax
  801e88:	c9                   	leaveq 
  801e89:	c3                   	retq   

0000000000801e8a <sys_getenvid>:
  801e8a:	55                   	push   %rbp
  801e8b:	48 89 e5             	mov    %rsp,%rbp
  801e8e:	48 83 ec 10          	sub    $0x10,%rsp
  801e92:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801e99:	00 
  801e9a:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801ea0:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801ea6:	b9 00 00 00 00       	mov    $0x0,%ecx
  801eab:	ba 00 00 00 00       	mov    $0x0,%edx
  801eb0:	be 00 00 00 00       	mov    $0x0,%esi
  801eb5:	bf 02 00 00 00       	mov    $0x2,%edi
  801eba:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801ec1:	00 00 00 
  801ec4:	ff d0                	callq  *%rax
  801ec6:	c9                   	leaveq 
  801ec7:	c3                   	retq   

0000000000801ec8 <sys_yield>:
  801ec8:	55                   	push   %rbp
  801ec9:	48 89 e5             	mov    %rsp,%rbp
  801ecc:	48 83 ec 10          	sub    $0x10,%rsp
  801ed0:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801ed7:	00 
  801ed8:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801ede:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801ee4:	b9 00 00 00 00       	mov    $0x0,%ecx
  801ee9:	ba 00 00 00 00       	mov    $0x0,%edx
  801eee:	be 00 00 00 00       	mov    $0x0,%esi
  801ef3:	bf 0b 00 00 00       	mov    $0xb,%edi
  801ef8:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801eff:	00 00 00 
  801f02:	ff d0                	callq  *%rax
  801f04:	c9                   	leaveq 
  801f05:	c3                   	retq   

0000000000801f06 <sys_page_alloc>:
  801f06:	55                   	push   %rbp
  801f07:	48 89 e5             	mov    %rsp,%rbp
  801f0a:	48 83 ec 20          	sub    $0x20,%rsp
  801f0e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801f11:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801f15:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801f18:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801f1b:	48 63 c8             	movslq %eax,%rcx
  801f1e:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801f22:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801f25:	48 98                	cltq   
  801f27:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801f2e:	00 
  801f2f:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801f35:	49 89 c8             	mov    %rcx,%r8
  801f38:	48 89 d1             	mov    %rdx,%rcx
  801f3b:	48 89 c2             	mov    %rax,%rdx
  801f3e:	be 01 00 00 00       	mov    $0x1,%esi
  801f43:	bf 04 00 00 00       	mov    $0x4,%edi
  801f48:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801f4f:	00 00 00 
  801f52:	ff d0                	callq  *%rax
  801f54:	c9                   	leaveq 
  801f55:	c3                   	retq   

0000000000801f56 <sys_page_map>:
  801f56:	55                   	push   %rbp
  801f57:	48 89 e5             	mov    %rsp,%rbp
  801f5a:	48 83 ec 30          	sub    $0x30,%rsp
  801f5e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801f61:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801f65:	89 55 f8             	mov    %edx,-0x8(%rbp)
  801f68:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  801f6c:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  801f70:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  801f73:	48 63 c8             	movslq %eax,%rcx
  801f76:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  801f7a:	8b 45 f8             	mov    -0x8(%rbp),%eax
  801f7d:	48 63 f0             	movslq %eax,%rsi
  801f80:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801f84:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801f87:	48 98                	cltq   
  801f89:	48 89 0c 24          	mov    %rcx,(%rsp)
  801f8d:	49 89 f9             	mov    %rdi,%r9
  801f90:	49 89 f0             	mov    %rsi,%r8
  801f93:	48 89 d1             	mov    %rdx,%rcx
  801f96:	48 89 c2             	mov    %rax,%rdx
  801f99:	be 01 00 00 00       	mov    $0x1,%esi
  801f9e:	bf 05 00 00 00       	mov    $0x5,%edi
  801fa3:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801faa:	00 00 00 
  801fad:	ff d0                	callq  *%rax
  801faf:	c9                   	leaveq 
  801fb0:	c3                   	retq   

0000000000801fb1 <sys_page_unmap>:
  801fb1:	55                   	push   %rbp
  801fb2:	48 89 e5             	mov    %rsp,%rbp
  801fb5:	48 83 ec 20          	sub    $0x20,%rsp
  801fb9:	89 7d fc             	mov    %edi,-0x4(%rbp)
  801fbc:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  801fc0:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  801fc4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  801fc7:	48 98                	cltq   
  801fc9:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  801fd0:	00 
  801fd1:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  801fd7:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  801fdd:	48 89 d1             	mov    %rdx,%rcx
  801fe0:	48 89 c2             	mov    %rax,%rdx
  801fe3:	be 01 00 00 00       	mov    $0x1,%esi
  801fe8:	bf 06 00 00 00       	mov    $0x6,%edi
  801fed:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  801ff4:	00 00 00 
  801ff7:	ff d0                	callq  *%rax
  801ff9:	c9                   	leaveq 
  801ffa:	c3                   	retq   

0000000000801ffb <sys_env_set_status>:
  801ffb:	55                   	push   %rbp
  801ffc:	48 89 e5             	mov    %rsp,%rbp
  801fff:	48 83 ec 10          	sub    $0x10,%rsp
  802003:	89 7d fc             	mov    %edi,-0x4(%rbp)
  802006:	89 75 f8             	mov    %esi,-0x8(%rbp)
  802009:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80200c:	48 63 d0             	movslq %eax,%rdx
  80200f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802012:	48 98                	cltq   
  802014:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  80201b:	00 
  80201c:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802022:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802028:	48 89 d1             	mov    %rdx,%rcx
  80202b:	48 89 c2             	mov    %rax,%rdx
  80202e:	be 01 00 00 00       	mov    $0x1,%esi
  802033:	bf 08 00 00 00       	mov    $0x8,%edi
  802038:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  80203f:	00 00 00 
  802042:	ff d0                	callq  *%rax
  802044:	c9                   	leaveq 
  802045:	c3                   	retq   

0000000000802046 <sys_env_set_trapframe>:
  802046:	55                   	push   %rbp
  802047:	48 89 e5             	mov    %rsp,%rbp
  80204a:	48 83 ec 20          	sub    $0x20,%rsp
  80204e:	89 7d fc             	mov    %edi,-0x4(%rbp)
  802051:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802055:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802059:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80205c:	48 98                	cltq   
  80205e:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802065:	00 
  802066:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80206c:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802072:	48 89 d1             	mov    %rdx,%rcx
  802075:	48 89 c2             	mov    %rax,%rdx
  802078:	be 01 00 00 00       	mov    $0x1,%esi
  80207d:	bf 09 00 00 00       	mov    $0x9,%edi
  802082:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  802089:	00 00 00 
  80208c:	ff d0                	callq  *%rax
  80208e:	c9                   	leaveq 
  80208f:	c3                   	retq   

0000000000802090 <sys_env_set_pgfault_upcall>:
  802090:	55                   	push   %rbp
  802091:	48 89 e5             	mov    %rsp,%rbp
  802094:	48 83 ec 20          	sub    $0x20,%rsp
  802098:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80209b:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  80209f:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8020a3:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8020a6:	48 98                	cltq   
  8020a8:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8020af:	00 
  8020b0:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8020b6:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8020bc:	48 89 d1             	mov    %rdx,%rcx
  8020bf:	48 89 c2             	mov    %rax,%rdx
  8020c2:	be 01 00 00 00       	mov    $0x1,%esi
  8020c7:	bf 0a 00 00 00       	mov    $0xa,%edi
  8020cc:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  8020d3:	00 00 00 
  8020d6:	ff d0                	callq  *%rax
  8020d8:	c9                   	leaveq 
  8020d9:	c3                   	retq   

00000000008020da <sys_ipc_try_send>:
  8020da:	55                   	push   %rbp
  8020db:	48 89 e5             	mov    %rsp,%rbp
  8020de:	48 83 ec 20          	sub    $0x20,%rsp
  8020e2:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8020e5:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8020e9:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8020ed:	89 4d f8             	mov    %ecx,-0x8(%rbp)
  8020f0:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8020f3:	48 63 f0             	movslq %eax,%rsi
  8020f6:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8020fa:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8020fd:	48 98                	cltq   
  8020ff:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802103:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  80210a:	00 
  80210b:	49 89 f1             	mov    %rsi,%r9
  80210e:	49 89 c8             	mov    %rcx,%r8
  802111:	48 89 d1             	mov    %rdx,%rcx
  802114:	48 89 c2             	mov    %rax,%rdx
  802117:	be 00 00 00 00       	mov    $0x0,%esi
  80211c:	bf 0c 00 00 00       	mov    $0xc,%edi
  802121:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  802128:	00 00 00 
  80212b:	ff d0                	callq  *%rax
  80212d:	c9                   	leaveq 
  80212e:	c3                   	retq   

000000000080212f <sys_ipc_recv>:
  80212f:	55                   	push   %rbp
  802130:	48 89 e5             	mov    %rsp,%rbp
  802133:	48 83 ec 10          	sub    $0x10,%rsp
  802137:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80213b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80213f:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802146:	00 
  802147:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80214d:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802153:	b9 00 00 00 00       	mov    $0x0,%ecx
  802158:	48 89 c2             	mov    %rax,%rdx
  80215b:	be 01 00 00 00       	mov    $0x1,%esi
  802160:	bf 0d 00 00 00       	mov    $0xd,%edi
  802165:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  80216c:	00 00 00 
  80216f:	ff d0                	callq  *%rax
  802171:	c9                   	leaveq 
  802172:	c3                   	retq   

0000000000802173 <sys_time_msec>:
  802173:	55                   	push   %rbp
  802174:	48 89 e5             	mov    %rsp,%rbp
  802177:	48 83 ec 10          	sub    $0x10,%rsp
  80217b:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802182:	00 
  802183:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802189:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  80218f:	b9 00 00 00 00       	mov    $0x0,%ecx
  802194:	ba 00 00 00 00       	mov    $0x0,%edx
  802199:	be 00 00 00 00       	mov    $0x0,%esi
  80219e:	bf 0e 00 00 00       	mov    $0xe,%edi
  8021a3:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  8021aa:	00 00 00 
  8021ad:	ff d0                	callq  *%rax
  8021af:	c9                   	leaveq 
  8021b0:	c3                   	retq   

00000000008021b1 <sys_net_transmit>:
  8021b1:	55                   	push   %rbp
  8021b2:	48 89 e5             	mov    %rsp,%rbp
  8021b5:	48 83 ec 20          	sub    $0x20,%rsp
  8021b9:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8021bd:	89 75 f4             	mov    %esi,-0xc(%rbp)
  8021c0:	8b 55 f4             	mov    -0xc(%rbp),%edx
  8021c3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8021c7:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8021ce:	00 
  8021cf:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8021d5:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8021db:	48 89 d1             	mov    %rdx,%rcx
  8021de:	48 89 c2             	mov    %rax,%rdx
  8021e1:	be 00 00 00 00       	mov    $0x0,%esi
  8021e6:	bf 0f 00 00 00       	mov    $0xf,%edi
  8021eb:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  8021f2:	00 00 00 
  8021f5:	ff d0                	callq  *%rax
  8021f7:	c9                   	leaveq 
  8021f8:	c3                   	retq   

00000000008021f9 <sys_net_receive>:
  8021f9:	55                   	push   %rbp
  8021fa:	48 89 e5             	mov    %rsp,%rbp
  8021fd:	48 83 ec 20          	sub    $0x20,%rsp
  802201:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802205:	89 75 f4             	mov    %esi,-0xc(%rbp)
  802208:	8b 55 f4             	mov    -0xc(%rbp),%edx
  80220b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80220f:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802216:	00 
  802217:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80221d:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802223:	48 89 d1             	mov    %rdx,%rcx
  802226:	48 89 c2             	mov    %rax,%rdx
  802229:	be 00 00 00 00       	mov    $0x0,%esi
  80222e:	bf 10 00 00 00       	mov    $0x10,%edi
  802233:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  80223a:	00 00 00 
  80223d:	ff d0                	callq  *%rax
  80223f:	c9                   	leaveq 
  802240:	c3                   	retq   

0000000000802241 <sys_ept_map>:
  802241:	55                   	push   %rbp
  802242:	48 89 e5             	mov    %rsp,%rbp
  802245:	48 83 ec 30          	sub    $0x30,%rsp
  802249:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80224c:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802250:	89 55 f8             	mov    %edx,-0x8(%rbp)
  802253:	48 89 4d e8          	mov    %rcx,-0x18(%rbp)
  802257:	44 89 45 e4          	mov    %r8d,-0x1c(%rbp)
  80225b:	8b 45 e4             	mov    -0x1c(%rbp),%eax
  80225e:	48 63 c8             	movslq %eax,%rcx
  802261:	48 8b 7d e8          	mov    -0x18(%rbp),%rdi
  802265:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802268:	48 63 f0             	movslq %eax,%rsi
  80226b:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  80226f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802272:	48 98                	cltq   
  802274:	48 89 0c 24          	mov    %rcx,(%rsp)
  802278:	49 89 f9             	mov    %rdi,%r9
  80227b:	49 89 f0             	mov    %rsi,%r8
  80227e:	48 89 d1             	mov    %rdx,%rcx
  802281:	48 89 c2             	mov    %rax,%rdx
  802284:	be 00 00 00 00       	mov    $0x0,%esi
  802289:	bf 11 00 00 00       	mov    $0x11,%edi
  80228e:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  802295:	00 00 00 
  802298:	ff d0                	callq  *%rax
  80229a:	c9                   	leaveq 
  80229b:	c3                   	retq   

000000000080229c <sys_env_mkguest>:
  80229c:	55                   	push   %rbp
  80229d:	48 89 e5             	mov    %rsp,%rbp
  8022a0:	48 83 ec 20          	sub    $0x20,%rsp
  8022a4:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8022a8:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8022ac:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8022b0:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8022b4:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8022bb:	00 
  8022bc:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8022c2:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8022c8:	48 89 d1             	mov    %rdx,%rcx
  8022cb:	48 89 c2             	mov    %rax,%rdx
  8022ce:	be 00 00 00 00       	mov    $0x0,%esi
  8022d3:	bf 12 00 00 00       	mov    $0x12,%edi
  8022d8:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  8022df:	00 00 00 
  8022e2:	ff d0                	callq  *%rax
  8022e4:	c9                   	leaveq 
  8022e5:	c3                   	retq   

00000000008022e6 <sys_vmx_list_vms>:
  8022e6:	55                   	push   %rbp
  8022e7:	48 89 e5             	mov    %rsp,%rbp
  8022ea:	48 83 ec 10          	sub    $0x10,%rsp
  8022ee:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8022f5:	00 
  8022f6:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8022fc:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802302:	b9 00 00 00 00       	mov    $0x0,%ecx
  802307:	ba 00 00 00 00       	mov    $0x0,%edx
  80230c:	be 00 00 00 00       	mov    $0x0,%esi
  802311:	bf 13 00 00 00       	mov    $0x13,%edi
  802316:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  80231d:	00 00 00 
  802320:	ff d0                	callq  *%rax
  802322:	c9                   	leaveq 
  802323:	c3                   	retq   

0000000000802324 <sys_vmx_sel_resume>:
  802324:	55                   	push   %rbp
  802325:	48 89 e5             	mov    %rsp,%rbp
  802328:	48 83 ec 10          	sub    $0x10,%rsp
  80232c:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80232f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802332:	48 98                	cltq   
  802334:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  80233b:	00 
  80233c:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  802342:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802348:	b9 00 00 00 00       	mov    $0x0,%ecx
  80234d:	48 89 c2             	mov    %rax,%rdx
  802350:	be 00 00 00 00       	mov    $0x0,%esi
  802355:	bf 14 00 00 00       	mov    $0x14,%edi
  80235a:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  802361:	00 00 00 
  802364:	ff d0                	callq  *%rax
  802366:	c9                   	leaveq 
  802367:	c3                   	retq   

0000000000802368 <sys_vmx_get_vmdisk_number>:
  802368:	55                   	push   %rbp
  802369:	48 89 e5             	mov    %rsp,%rbp
  80236c:	48 83 ec 10          	sub    $0x10,%rsp
  802370:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  802377:	00 
  802378:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  80237e:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  802384:	b9 00 00 00 00       	mov    $0x0,%ecx
  802389:	ba 00 00 00 00       	mov    $0x0,%edx
  80238e:	be 00 00 00 00       	mov    $0x0,%esi
  802393:	bf 15 00 00 00       	mov    $0x15,%edi
  802398:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  80239f:	00 00 00 
  8023a2:	ff d0                	callq  *%rax
  8023a4:	c9                   	leaveq 
  8023a5:	c3                   	retq   

00000000008023a6 <sys_vmx_incr_vmdisk_number>:
  8023a6:	55                   	push   %rbp
  8023a7:	48 89 e5             	mov    %rsp,%rbp
  8023aa:	48 83 ec 10          	sub    $0x10,%rsp
  8023ae:	48 c7 04 24 00 00 00 	movq   $0x0,(%rsp)
  8023b5:	00 
  8023b6:	41 b9 00 00 00 00    	mov    $0x0,%r9d
  8023bc:	41 b8 00 00 00 00    	mov    $0x0,%r8d
  8023c2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8023c7:	ba 00 00 00 00       	mov    $0x0,%edx
  8023cc:	be 00 00 00 00       	mov    $0x0,%esi
  8023d1:	bf 16 00 00 00       	mov    $0x16,%edi
  8023d6:	48 b8 30 1d 80 00 00 	movabs $0x801d30,%rax
  8023dd:	00 00 00 
  8023e0:	ff d0                	callq  *%rax
  8023e2:	c9                   	leaveq 
  8023e3:	c3                   	retq   

00000000008023e4 <fd2num>:
  8023e4:	55                   	push   %rbp
  8023e5:	48 89 e5             	mov    %rsp,%rbp
  8023e8:	48 83 ec 08          	sub    $0x8,%rsp
  8023ec:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8023f0:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8023f4:	48 b8 00 00 00 30 ff 	movabs $0xffffffff30000000,%rax
  8023fb:	ff ff ff 
  8023fe:	48 01 d0             	add    %rdx,%rax
  802401:	48 c1 e8 0c          	shr    $0xc,%rax
  802405:	c9                   	leaveq 
  802406:	c3                   	retq   

0000000000802407 <fd2data>:
  802407:	55                   	push   %rbp
  802408:	48 89 e5             	mov    %rsp,%rbp
  80240b:	48 83 ec 08          	sub    $0x8,%rsp
  80240f:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802413:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802417:	48 89 c7             	mov    %rax,%rdi
  80241a:	48 b8 e4 23 80 00 00 	movabs $0x8023e4,%rax
  802421:	00 00 00 
  802424:	ff d0                	callq  *%rax
  802426:	48 05 20 00 0d 00    	add    $0xd0020,%rax
  80242c:	48 c1 e0 0c          	shl    $0xc,%rax
  802430:	c9                   	leaveq 
  802431:	c3                   	retq   

0000000000802432 <fd_alloc>:
  802432:	55                   	push   %rbp
  802433:	48 89 e5             	mov    %rsp,%rbp
  802436:	48 83 ec 18          	sub    $0x18,%rsp
  80243a:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80243e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802445:	eb 6b                	jmp    8024b2 <fd_alloc+0x80>
  802447:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80244a:	48 98                	cltq   
  80244c:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  802452:	48 c1 e0 0c          	shl    $0xc,%rax
  802456:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80245a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80245e:	48 c1 e8 15          	shr    $0x15,%rax
  802462:	48 89 c2             	mov    %rax,%rdx
  802465:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  80246c:	01 00 00 
  80246f:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802473:	83 e0 01             	and    $0x1,%eax
  802476:	48 85 c0             	test   %rax,%rax
  802479:	74 21                	je     80249c <fd_alloc+0x6a>
  80247b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80247f:	48 c1 e8 0c          	shr    $0xc,%rax
  802483:	48 89 c2             	mov    %rax,%rdx
  802486:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  80248d:	01 00 00 
  802490:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802494:	83 e0 01             	and    $0x1,%eax
  802497:	48 85 c0             	test   %rax,%rax
  80249a:	75 12                	jne    8024ae <fd_alloc+0x7c>
  80249c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8024a0:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8024a4:	48 89 10             	mov    %rdx,(%rax)
  8024a7:	b8 00 00 00 00       	mov    $0x0,%eax
  8024ac:	eb 1a                	jmp    8024c8 <fd_alloc+0x96>
  8024ae:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8024b2:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  8024b6:	7e 8f                	jle    802447 <fd_alloc+0x15>
  8024b8:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8024bc:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  8024c3:	b8 f5 ff ff ff       	mov    $0xfffffff5,%eax
  8024c8:	c9                   	leaveq 
  8024c9:	c3                   	retq   

00000000008024ca <fd_lookup>:
  8024ca:	55                   	push   %rbp
  8024cb:	48 89 e5             	mov    %rsp,%rbp
  8024ce:	48 83 ec 20          	sub    $0x20,%rsp
  8024d2:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8024d5:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8024d9:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  8024dd:	78 06                	js     8024e5 <fd_lookup+0x1b>
  8024df:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%rbp)
  8024e3:	7e 07                	jle    8024ec <fd_lookup+0x22>
  8024e5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8024ea:	eb 6c                	jmp    802558 <fd_lookup+0x8e>
  8024ec:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8024ef:	48 98                	cltq   
  8024f1:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  8024f7:	48 c1 e0 0c          	shl    $0xc,%rax
  8024fb:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  8024ff:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802503:	48 c1 e8 15          	shr    $0x15,%rax
  802507:	48 89 c2             	mov    %rax,%rdx
  80250a:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  802511:	01 00 00 
  802514:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802518:	83 e0 01             	and    $0x1,%eax
  80251b:	48 85 c0             	test   %rax,%rax
  80251e:	74 21                	je     802541 <fd_lookup+0x77>
  802520:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802524:	48 c1 e8 0c          	shr    $0xc,%rax
  802528:	48 89 c2             	mov    %rax,%rdx
  80252b:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802532:	01 00 00 
  802535:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802539:	83 e0 01             	and    $0x1,%eax
  80253c:	48 85 c0             	test   %rax,%rax
  80253f:	75 07                	jne    802548 <fd_lookup+0x7e>
  802541:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802546:	eb 10                	jmp    802558 <fd_lookup+0x8e>
  802548:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80254c:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  802550:	48 89 10             	mov    %rdx,(%rax)
  802553:	b8 00 00 00 00       	mov    $0x0,%eax
  802558:	c9                   	leaveq 
  802559:	c3                   	retq   

000000000080255a <fd_close>:
  80255a:	55                   	push   %rbp
  80255b:	48 89 e5             	mov    %rsp,%rbp
  80255e:	48 83 ec 30          	sub    $0x30,%rsp
  802562:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  802566:	89 f0                	mov    %esi,%eax
  802568:	88 45 d4             	mov    %al,-0x2c(%rbp)
  80256b:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80256f:	48 89 c7             	mov    %rax,%rdi
  802572:	48 b8 e4 23 80 00 00 	movabs $0x8023e4,%rax
  802579:	00 00 00 
  80257c:	ff d0                	callq  *%rax
  80257e:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802582:	48 89 d6             	mov    %rdx,%rsi
  802585:	89 c7                	mov    %eax,%edi
  802587:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  80258e:	00 00 00 
  802591:	ff d0                	callq  *%rax
  802593:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802596:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80259a:	78 0a                	js     8025a6 <fd_close+0x4c>
  80259c:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8025a0:	48 39 45 d8          	cmp    %rax,-0x28(%rbp)
  8025a4:	74 12                	je     8025b8 <fd_close+0x5e>
  8025a6:	80 7d d4 00          	cmpb   $0x0,-0x2c(%rbp)
  8025aa:	74 05                	je     8025b1 <fd_close+0x57>
  8025ac:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8025af:	eb 05                	jmp    8025b6 <fd_close+0x5c>
  8025b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8025b6:	eb 69                	jmp    802621 <fd_close+0xc7>
  8025b8:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8025bc:	8b 00                	mov    (%rax),%eax
  8025be:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  8025c2:	48 89 d6             	mov    %rdx,%rsi
  8025c5:	89 c7                	mov    %eax,%edi
  8025c7:	48 b8 23 26 80 00 00 	movabs $0x802623,%rax
  8025ce:	00 00 00 
  8025d1:	ff d0                	callq  *%rax
  8025d3:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8025d6:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8025da:	78 2a                	js     802606 <fd_close+0xac>
  8025dc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8025e0:	48 8b 40 20          	mov    0x20(%rax),%rax
  8025e4:	48 85 c0             	test   %rax,%rax
  8025e7:	74 16                	je     8025ff <fd_close+0xa5>
  8025e9:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8025ed:	48 8b 40 20          	mov    0x20(%rax),%rax
  8025f1:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8025f5:	48 89 d7             	mov    %rdx,%rdi
  8025f8:	ff d0                	callq  *%rax
  8025fa:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8025fd:	eb 07                	jmp    802606 <fd_close+0xac>
  8025ff:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802606:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80260a:	48 89 c6             	mov    %rax,%rsi
  80260d:	bf 00 00 00 00       	mov    $0x0,%edi
  802612:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  802619:	00 00 00 
  80261c:	ff d0                	callq  *%rax
  80261e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802621:	c9                   	leaveq 
  802622:	c3                   	retq   

0000000000802623 <dev_lookup>:
  802623:	55                   	push   %rbp
  802624:	48 89 e5             	mov    %rsp,%rbp
  802627:	48 83 ec 20          	sub    $0x20,%rsp
  80262b:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80262e:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802632:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802639:	eb 41                	jmp    80267c <dev_lookup+0x59>
  80263b:	48 b8 20 70 80 00 00 	movabs $0x807020,%rax
  802642:	00 00 00 
  802645:	8b 55 fc             	mov    -0x4(%rbp),%edx
  802648:	48 63 d2             	movslq %edx,%rdx
  80264b:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80264f:	8b 00                	mov    (%rax),%eax
  802651:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  802654:	75 22                	jne    802678 <dev_lookup+0x55>
  802656:	48 b8 20 70 80 00 00 	movabs $0x807020,%rax
  80265d:	00 00 00 
  802660:	8b 55 fc             	mov    -0x4(%rbp),%edx
  802663:	48 63 d2             	movslq %edx,%rdx
  802666:	48 8b 14 d0          	mov    (%rax,%rdx,8),%rdx
  80266a:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80266e:	48 89 10             	mov    %rdx,(%rax)
  802671:	b8 00 00 00 00       	mov    $0x0,%eax
  802676:	eb 60                	jmp    8026d8 <dev_lookup+0xb5>
  802678:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80267c:	48 b8 20 70 80 00 00 	movabs $0x807020,%rax
  802683:	00 00 00 
  802686:	8b 55 fc             	mov    -0x4(%rbp),%edx
  802689:	48 63 d2             	movslq %edx,%rdx
  80268c:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802690:	48 85 c0             	test   %rax,%rax
  802693:	75 a6                	jne    80263b <dev_lookup+0x18>
  802695:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  80269c:	00 00 00 
  80269f:	48 8b 00             	mov    (%rax),%rax
  8026a2:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  8026a8:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8026ab:	89 c6                	mov    %eax,%esi
  8026ad:	48 bf 78 4e 80 00 00 	movabs $0x804e78,%rdi
  8026b4:	00 00 00 
  8026b7:	b8 00 00 00 00       	mov    $0x0,%eax
  8026bc:	48 b9 22 0a 80 00 00 	movabs $0x800a22,%rcx
  8026c3:	00 00 00 
  8026c6:	ff d1                	callq  *%rcx
  8026c8:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8026cc:	48 c7 00 00 00 00 00 	movq   $0x0,(%rax)
  8026d3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8026d8:	c9                   	leaveq 
  8026d9:	c3                   	retq   

00000000008026da <close>:
  8026da:	55                   	push   %rbp
  8026db:	48 89 e5             	mov    %rsp,%rbp
  8026de:	48 83 ec 20          	sub    $0x20,%rsp
  8026e2:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8026e5:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8026e9:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8026ec:	48 89 d6             	mov    %rdx,%rsi
  8026ef:	89 c7                	mov    %eax,%edi
  8026f1:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  8026f8:	00 00 00 
  8026fb:	ff d0                	callq  *%rax
  8026fd:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802700:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802704:	79 05                	jns    80270b <close+0x31>
  802706:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802709:	eb 18                	jmp    802723 <close+0x49>
  80270b:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80270f:	be 01 00 00 00       	mov    $0x1,%esi
  802714:	48 89 c7             	mov    %rax,%rdi
  802717:	48 b8 5a 25 80 00 00 	movabs $0x80255a,%rax
  80271e:	00 00 00 
  802721:	ff d0                	callq  *%rax
  802723:	c9                   	leaveq 
  802724:	c3                   	retq   

0000000000802725 <close_all>:
  802725:	55                   	push   %rbp
  802726:	48 89 e5             	mov    %rsp,%rbp
  802729:	48 83 ec 10          	sub    $0x10,%rsp
  80272d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  802734:	eb 15                	jmp    80274b <close_all+0x26>
  802736:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802739:	89 c7                	mov    %eax,%edi
  80273b:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  802742:	00 00 00 
  802745:	ff d0                	callq  *%rax
  802747:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  80274b:	83 7d fc 1f          	cmpl   $0x1f,-0x4(%rbp)
  80274f:	7e e5                	jle    802736 <close_all+0x11>
  802751:	c9                   	leaveq 
  802752:	c3                   	retq   

0000000000802753 <dup>:
  802753:	55                   	push   %rbp
  802754:	48 89 e5             	mov    %rsp,%rbp
  802757:	48 83 ec 40          	sub    $0x40,%rsp
  80275b:	89 7d cc             	mov    %edi,-0x34(%rbp)
  80275e:	89 75 c8             	mov    %esi,-0x38(%rbp)
  802761:	48 8d 55 d8          	lea    -0x28(%rbp),%rdx
  802765:	8b 45 cc             	mov    -0x34(%rbp),%eax
  802768:	48 89 d6             	mov    %rdx,%rsi
  80276b:	89 c7                	mov    %eax,%edi
  80276d:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  802774:	00 00 00 
  802777:	ff d0                	callq  *%rax
  802779:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80277c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802780:	79 08                	jns    80278a <dup+0x37>
  802782:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802785:	e9 70 01 00 00       	jmpq   8028fa <dup+0x1a7>
  80278a:	8b 45 c8             	mov    -0x38(%rbp),%eax
  80278d:	89 c7                	mov    %eax,%edi
  80278f:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  802796:	00 00 00 
  802799:	ff d0                	callq  *%rax
  80279b:	8b 45 c8             	mov    -0x38(%rbp),%eax
  80279e:	48 98                	cltq   
  8027a0:	48 05 00 00 0d 00    	add    $0xd0000,%rax
  8027a6:	48 c1 e0 0c          	shl    $0xc,%rax
  8027aa:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  8027ae:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8027b2:	48 89 c7             	mov    %rax,%rdi
  8027b5:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  8027bc:	00 00 00 
  8027bf:	ff d0                	callq  *%rax
  8027c1:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  8027c5:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8027c9:	48 89 c7             	mov    %rax,%rdi
  8027cc:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  8027d3:	00 00 00 
  8027d6:	ff d0                	callq  *%rax
  8027d8:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  8027dc:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8027e0:	48 c1 e8 15          	shr    $0x15,%rax
  8027e4:	48 89 c2             	mov    %rax,%rdx
  8027e7:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  8027ee:	01 00 00 
  8027f1:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  8027f5:	83 e0 01             	and    $0x1,%eax
  8027f8:	48 85 c0             	test   %rax,%rax
  8027fb:	74 73                	je     802870 <dup+0x11d>
  8027fd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802801:	48 c1 e8 0c          	shr    $0xc,%rax
  802805:	48 89 c2             	mov    %rax,%rdx
  802808:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  80280f:	01 00 00 
  802812:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802816:	83 e0 01             	and    $0x1,%eax
  802819:	48 85 c0             	test   %rax,%rax
  80281c:	74 52                	je     802870 <dup+0x11d>
  80281e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802822:	48 c1 e8 0c          	shr    $0xc,%rax
  802826:	48 89 c2             	mov    %rax,%rdx
  802829:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802830:	01 00 00 
  802833:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802837:	25 07 0e 00 00       	and    $0xe07,%eax
  80283c:	89 c1                	mov    %eax,%ecx
  80283e:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  802842:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802846:	41 89 c8             	mov    %ecx,%r8d
  802849:	48 89 d1             	mov    %rdx,%rcx
  80284c:	ba 00 00 00 00       	mov    $0x0,%edx
  802851:	48 89 c6             	mov    %rax,%rsi
  802854:	bf 00 00 00 00       	mov    $0x0,%edi
  802859:	48 b8 56 1f 80 00 00 	movabs $0x801f56,%rax
  802860:	00 00 00 
  802863:	ff d0                	callq  *%rax
  802865:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802868:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80286c:	79 02                	jns    802870 <dup+0x11d>
  80286e:	eb 57                	jmp    8028c7 <dup+0x174>
  802870:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802874:	48 c1 e8 0c          	shr    $0xc,%rax
  802878:	48 89 c2             	mov    %rax,%rdx
  80287b:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  802882:	01 00 00 
  802885:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  802889:	25 07 0e 00 00       	and    $0xe07,%eax
  80288e:	89 c1                	mov    %eax,%ecx
  802890:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  802894:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802898:	41 89 c8             	mov    %ecx,%r8d
  80289b:	48 89 d1             	mov    %rdx,%rcx
  80289e:	ba 00 00 00 00       	mov    $0x0,%edx
  8028a3:	48 89 c6             	mov    %rax,%rsi
  8028a6:	bf 00 00 00 00       	mov    $0x0,%edi
  8028ab:	48 b8 56 1f 80 00 00 	movabs $0x801f56,%rax
  8028b2:	00 00 00 
  8028b5:	ff d0                	callq  *%rax
  8028b7:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8028ba:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8028be:	79 02                	jns    8028c2 <dup+0x16f>
  8028c0:	eb 05                	jmp    8028c7 <dup+0x174>
  8028c2:	8b 45 c8             	mov    -0x38(%rbp),%eax
  8028c5:	eb 33                	jmp    8028fa <dup+0x1a7>
  8028c7:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8028cb:	48 89 c6             	mov    %rax,%rsi
  8028ce:	bf 00 00 00 00       	mov    $0x0,%edi
  8028d3:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  8028da:	00 00 00 
  8028dd:	ff d0                	callq  *%rax
  8028df:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8028e3:	48 89 c6             	mov    %rax,%rsi
  8028e6:	bf 00 00 00 00       	mov    $0x0,%edi
  8028eb:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  8028f2:	00 00 00 
  8028f5:	ff d0                	callq  *%rax
  8028f7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8028fa:	c9                   	leaveq 
  8028fb:	c3                   	retq   

00000000008028fc <read>:
  8028fc:	55                   	push   %rbp
  8028fd:	48 89 e5             	mov    %rsp,%rbp
  802900:	48 83 ec 40          	sub    $0x40,%rsp
  802904:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802907:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  80290b:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  80290f:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802913:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802916:	48 89 d6             	mov    %rdx,%rsi
  802919:	89 c7                	mov    %eax,%edi
  80291b:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  802922:	00 00 00 
  802925:	ff d0                	callq  *%rax
  802927:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80292a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80292e:	78 24                	js     802954 <read+0x58>
  802930:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802934:	8b 00                	mov    (%rax),%eax
  802936:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80293a:	48 89 d6             	mov    %rdx,%rsi
  80293d:	89 c7                	mov    %eax,%edi
  80293f:	48 b8 23 26 80 00 00 	movabs $0x802623,%rax
  802946:	00 00 00 
  802949:	ff d0                	callq  *%rax
  80294b:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80294e:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802952:	79 05                	jns    802959 <read+0x5d>
  802954:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802957:	eb 76                	jmp    8029cf <read+0xd3>
  802959:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80295d:	8b 40 08             	mov    0x8(%rax),%eax
  802960:	83 e0 03             	and    $0x3,%eax
  802963:	83 f8 01             	cmp    $0x1,%eax
  802966:	75 3a                	jne    8029a2 <read+0xa6>
  802968:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  80296f:	00 00 00 
  802972:	48 8b 00             	mov    (%rax),%rax
  802975:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  80297b:	8b 55 dc             	mov    -0x24(%rbp),%edx
  80297e:	89 c6                	mov    %eax,%esi
  802980:	48 bf 97 4e 80 00 00 	movabs $0x804e97,%rdi
  802987:	00 00 00 
  80298a:	b8 00 00 00 00       	mov    $0x0,%eax
  80298f:	48 b9 22 0a 80 00 00 	movabs $0x800a22,%rcx
  802996:	00 00 00 
  802999:	ff d1                	callq  *%rcx
  80299b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  8029a0:	eb 2d                	jmp    8029cf <read+0xd3>
  8029a2:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8029a6:	48 8b 40 10          	mov    0x10(%rax),%rax
  8029aa:	48 85 c0             	test   %rax,%rax
  8029ad:	75 07                	jne    8029b6 <read+0xba>
  8029af:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  8029b4:	eb 19                	jmp    8029cf <read+0xd3>
  8029b6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8029ba:	48 8b 40 10          	mov    0x10(%rax),%rax
  8029be:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8029c2:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  8029c6:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  8029ca:	48 89 cf             	mov    %rcx,%rdi
  8029cd:	ff d0                	callq  *%rax
  8029cf:	c9                   	leaveq 
  8029d0:	c3                   	retq   

00000000008029d1 <readn>:
  8029d1:	55                   	push   %rbp
  8029d2:	48 89 e5             	mov    %rsp,%rbp
  8029d5:	48 83 ec 30          	sub    $0x30,%rsp
  8029d9:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8029dc:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8029e0:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8029e4:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  8029eb:	eb 49                	jmp    802a36 <readn+0x65>
  8029ed:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8029f0:	48 98                	cltq   
  8029f2:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  8029f6:	48 29 c2             	sub    %rax,%rdx
  8029f9:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8029fc:	48 63 c8             	movslq %eax,%rcx
  8029ff:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802a03:	48 01 c1             	add    %rax,%rcx
  802a06:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802a09:	48 89 ce             	mov    %rcx,%rsi
  802a0c:	89 c7                	mov    %eax,%edi
  802a0e:	48 b8 fc 28 80 00 00 	movabs $0x8028fc,%rax
  802a15:	00 00 00 
  802a18:	ff d0                	callq  *%rax
  802a1a:	89 45 f8             	mov    %eax,-0x8(%rbp)
  802a1d:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  802a21:	79 05                	jns    802a28 <readn+0x57>
  802a23:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802a26:	eb 1c                	jmp    802a44 <readn+0x73>
  802a28:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  802a2c:	75 02                	jne    802a30 <readn+0x5f>
  802a2e:	eb 11                	jmp    802a41 <readn+0x70>
  802a30:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802a33:	01 45 fc             	add    %eax,-0x4(%rbp)
  802a36:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802a39:	48 98                	cltq   
  802a3b:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  802a3f:	72 ac                	jb     8029ed <readn+0x1c>
  802a41:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802a44:	c9                   	leaveq 
  802a45:	c3                   	retq   

0000000000802a46 <write>:
  802a46:	55                   	push   %rbp
  802a47:	48 89 e5             	mov    %rsp,%rbp
  802a4a:	48 83 ec 40          	sub    $0x40,%rsp
  802a4e:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802a51:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802a55:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802a59:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802a5d:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802a60:	48 89 d6             	mov    %rdx,%rsi
  802a63:	89 c7                	mov    %eax,%edi
  802a65:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  802a6c:	00 00 00 
  802a6f:	ff d0                	callq  *%rax
  802a71:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802a74:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802a78:	78 24                	js     802a9e <write+0x58>
  802a7a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802a7e:	8b 00                	mov    (%rax),%eax
  802a80:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802a84:	48 89 d6             	mov    %rdx,%rsi
  802a87:	89 c7                	mov    %eax,%edi
  802a89:	48 b8 23 26 80 00 00 	movabs $0x802623,%rax
  802a90:	00 00 00 
  802a93:	ff d0                	callq  *%rax
  802a95:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802a98:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802a9c:	79 05                	jns    802aa3 <write+0x5d>
  802a9e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802aa1:	eb 75                	jmp    802b18 <write+0xd2>
  802aa3:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802aa7:	8b 40 08             	mov    0x8(%rax),%eax
  802aaa:	83 e0 03             	and    $0x3,%eax
  802aad:	85 c0                	test   %eax,%eax
  802aaf:	75 3a                	jne    802aeb <write+0xa5>
  802ab1:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  802ab8:	00 00 00 
  802abb:	48 8b 00             	mov    (%rax),%rax
  802abe:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  802ac4:	8b 55 dc             	mov    -0x24(%rbp),%edx
  802ac7:	89 c6                	mov    %eax,%esi
  802ac9:	48 bf b3 4e 80 00 00 	movabs $0x804eb3,%rdi
  802ad0:	00 00 00 
  802ad3:	b8 00 00 00 00       	mov    $0x0,%eax
  802ad8:	48 b9 22 0a 80 00 00 	movabs $0x800a22,%rcx
  802adf:	00 00 00 
  802ae2:	ff d1                	callq  *%rcx
  802ae4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802ae9:	eb 2d                	jmp    802b18 <write+0xd2>
  802aeb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802aef:	48 8b 40 18          	mov    0x18(%rax),%rax
  802af3:	48 85 c0             	test   %rax,%rax
  802af6:	75 07                	jne    802aff <write+0xb9>
  802af8:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802afd:	eb 19                	jmp    802b18 <write+0xd2>
  802aff:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802b03:	48 8b 40 18          	mov    0x18(%rax),%rax
  802b07:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  802b0b:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  802b0f:	48 8b 75 d0          	mov    -0x30(%rbp),%rsi
  802b13:	48 89 cf             	mov    %rcx,%rdi
  802b16:	ff d0                	callq  *%rax
  802b18:	c9                   	leaveq 
  802b19:	c3                   	retq   

0000000000802b1a <seek>:
  802b1a:	55                   	push   %rbp
  802b1b:	48 89 e5             	mov    %rsp,%rbp
  802b1e:	48 83 ec 18          	sub    $0x18,%rsp
  802b22:	89 7d ec             	mov    %edi,-0x14(%rbp)
  802b25:	89 75 e8             	mov    %esi,-0x18(%rbp)
  802b28:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802b2c:	8b 45 ec             	mov    -0x14(%rbp),%eax
  802b2f:	48 89 d6             	mov    %rdx,%rsi
  802b32:	89 c7                	mov    %eax,%edi
  802b34:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  802b3b:	00 00 00 
  802b3e:	ff d0                	callq  *%rax
  802b40:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802b43:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802b47:	79 05                	jns    802b4e <seek+0x34>
  802b49:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802b4c:	eb 0f                	jmp    802b5d <seek+0x43>
  802b4e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802b52:	8b 55 e8             	mov    -0x18(%rbp),%edx
  802b55:	89 50 04             	mov    %edx,0x4(%rax)
  802b58:	b8 00 00 00 00       	mov    $0x0,%eax
  802b5d:	c9                   	leaveq 
  802b5e:	c3                   	retq   

0000000000802b5f <ftruncate>:
  802b5f:	55                   	push   %rbp
  802b60:	48 89 e5             	mov    %rsp,%rbp
  802b63:	48 83 ec 30          	sub    $0x30,%rsp
  802b67:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802b6a:	89 75 d8             	mov    %esi,-0x28(%rbp)
  802b6d:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802b71:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802b74:	48 89 d6             	mov    %rdx,%rsi
  802b77:	89 c7                	mov    %eax,%edi
  802b79:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  802b80:	00 00 00 
  802b83:	ff d0                	callq  *%rax
  802b85:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802b88:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802b8c:	78 24                	js     802bb2 <ftruncate+0x53>
  802b8e:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802b92:	8b 00                	mov    (%rax),%eax
  802b94:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802b98:	48 89 d6             	mov    %rdx,%rsi
  802b9b:	89 c7                	mov    %eax,%edi
  802b9d:	48 b8 23 26 80 00 00 	movabs $0x802623,%rax
  802ba4:	00 00 00 
  802ba7:	ff d0                	callq  *%rax
  802ba9:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802bac:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802bb0:	79 05                	jns    802bb7 <ftruncate+0x58>
  802bb2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802bb5:	eb 72                	jmp    802c29 <ftruncate+0xca>
  802bb7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802bbb:	8b 40 08             	mov    0x8(%rax),%eax
  802bbe:	83 e0 03             	and    $0x3,%eax
  802bc1:	85 c0                	test   %eax,%eax
  802bc3:	75 3a                	jne    802bff <ftruncate+0xa0>
  802bc5:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  802bcc:	00 00 00 
  802bcf:	48 8b 00             	mov    (%rax),%rax
  802bd2:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  802bd8:	8b 55 dc             	mov    -0x24(%rbp),%edx
  802bdb:	89 c6                	mov    %eax,%esi
  802bdd:	48 bf d0 4e 80 00 00 	movabs $0x804ed0,%rdi
  802be4:	00 00 00 
  802be7:	b8 00 00 00 00       	mov    $0x0,%eax
  802bec:	48 b9 22 0a 80 00 00 	movabs $0x800a22,%rcx
  802bf3:	00 00 00 
  802bf6:	ff d1                	callq  *%rcx
  802bf8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
  802bfd:	eb 2a                	jmp    802c29 <ftruncate+0xca>
  802bff:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802c03:	48 8b 40 30          	mov    0x30(%rax),%rax
  802c07:	48 85 c0             	test   %rax,%rax
  802c0a:	75 07                	jne    802c13 <ftruncate+0xb4>
  802c0c:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802c11:	eb 16                	jmp    802c29 <ftruncate+0xca>
  802c13:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802c17:	48 8b 40 30          	mov    0x30(%rax),%rax
  802c1b:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  802c1f:	8b 4d d8             	mov    -0x28(%rbp),%ecx
  802c22:	89 ce                	mov    %ecx,%esi
  802c24:	48 89 d7             	mov    %rdx,%rdi
  802c27:	ff d0                	callq  *%rax
  802c29:	c9                   	leaveq 
  802c2a:	c3                   	retq   

0000000000802c2b <fstat>:
  802c2b:	55                   	push   %rbp
  802c2c:	48 89 e5             	mov    %rsp,%rbp
  802c2f:	48 83 ec 30          	sub    $0x30,%rsp
  802c33:	89 7d dc             	mov    %edi,-0x24(%rbp)
  802c36:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802c3a:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  802c3e:	8b 45 dc             	mov    -0x24(%rbp),%eax
  802c41:	48 89 d6             	mov    %rdx,%rsi
  802c44:	89 c7                	mov    %eax,%edi
  802c46:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  802c4d:	00 00 00 
  802c50:	ff d0                	callq  *%rax
  802c52:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802c55:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802c59:	78 24                	js     802c7f <fstat+0x54>
  802c5b:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802c5f:	8b 00                	mov    (%rax),%eax
  802c61:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  802c65:	48 89 d6             	mov    %rdx,%rsi
  802c68:	89 c7                	mov    %eax,%edi
  802c6a:	48 b8 23 26 80 00 00 	movabs $0x802623,%rax
  802c71:	00 00 00 
  802c74:	ff d0                	callq  *%rax
  802c76:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802c79:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802c7d:	79 05                	jns    802c84 <fstat+0x59>
  802c7f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802c82:	eb 5e                	jmp    802ce2 <fstat+0xb7>
  802c84:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802c88:	48 8b 40 28          	mov    0x28(%rax),%rax
  802c8c:	48 85 c0             	test   %rax,%rax
  802c8f:	75 07                	jne    802c98 <fstat+0x6d>
  802c91:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  802c96:	eb 4a                	jmp    802ce2 <fstat+0xb7>
  802c98:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802c9c:	c6 00 00             	movb   $0x0,(%rax)
  802c9f:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802ca3:	c7 80 80 00 00 00 00 	movl   $0x0,0x80(%rax)
  802caa:	00 00 00 
  802cad:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802cb1:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  802cb8:	00 00 00 
  802cbb:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  802cbf:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  802cc3:	48 89 90 88 00 00 00 	mov    %rdx,0x88(%rax)
  802cca:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802cce:	48 8b 40 28          	mov    0x28(%rax),%rax
  802cd2:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  802cd6:	48 8b 4d d0          	mov    -0x30(%rbp),%rcx
  802cda:	48 89 ce             	mov    %rcx,%rsi
  802cdd:	48 89 d7             	mov    %rdx,%rdi
  802ce0:	ff d0                	callq  *%rax
  802ce2:	c9                   	leaveq 
  802ce3:	c3                   	retq   

0000000000802ce4 <stat>:
  802ce4:	55                   	push   %rbp
  802ce5:	48 89 e5             	mov    %rsp,%rbp
  802ce8:	48 83 ec 20          	sub    $0x20,%rsp
  802cec:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802cf0:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802cf4:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802cf8:	be 00 00 00 00       	mov    $0x0,%esi
  802cfd:	48 89 c7             	mov    %rax,%rdi
  802d00:	48 b8 d2 2d 80 00 00 	movabs $0x802dd2,%rax
  802d07:	00 00 00 
  802d0a:	ff d0                	callq  *%rax
  802d0c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802d0f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802d13:	79 05                	jns    802d1a <stat+0x36>
  802d15:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802d18:	eb 2f                	jmp    802d49 <stat+0x65>
  802d1a:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  802d1e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802d21:	48 89 d6             	mov    %rdx,%rsi
  802d24:	89 c7                	mov    %eax,%edi
  802d26:	48 b8 2b 2c 80 00 00 	movabs $0x802c2b,%rax
  802d2d:	00 00 00 
  802d30:	ff d0                	callq  *%rax
  802d32:	89 45 f8             	mov    %eax,-0x8(%rbp)
  802d35:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802d38:	89 c7                	mov    %eax,%edi
  802d3a:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  802d41:	00 00 00 
  802d44:	ff d0                	callq  *%rax
  802d46:	8b 45 f8             	mov    -0x8(%rbp),%eax
  802d49:	c9                   	leaveq 
  802d4a:	c3                   	retq   

0000000000802d4b <fsipc>:
  802d4b:	55                   	push   %rbp
  802d4c:	48 89 e5             	mov    %rsp,%rbp
  802d4f:	48 83 ec 10          	sub    $0x10,%rsp
  802d53:	89 7d fc             	mov    %edi,-0x4(%rbp)
  802d56:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  802d5a:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d61:	00 00 00 
  802d64:	8b 00                	mov    (%rax),%eax
  802d66:	85 c0                	test   %eax,%eax
  802d68:	75 1d                	jne    802d87 <fsipc+0x3c>
  802d6a:	bf 01 00 00 00       	mov    $0x1,%edi
  802d6f:	48 b8 83 46 80 00 00 	movabs $0x804683,%rax
  802d76:	00 00 00 
  802d79:	ff d0                	callq  *%rax
  802d7b:	48 ba 00 80 80 00 00 	movabs $0x808000,%rdx
  802d82:	00 00 00 
  802d85:	89 02                	mov    %eax,(%rdx)
  802d87:	48 b8 00 80 80 00 00 	movabs $0x808000,%rax
  802d8e:	00 00 00 
  802d91:	8b 00                	mov    (%rax),%eax
  802d93:	8b 75 fc             	mov    -0x4(%rbp),%esi
  802d96:	b9 07 00 00 00       	mov    $0x7,%ecx
  802d9b:	48 ba 00 90 80 00 00 	movabs $0x809000,%rdx
  802da2:	00 00 00 
  802da5:	89 c7                	mov    %eax,%edi
  802da7:	48 b8 ed 45 80 00 00 	movabs $0x8045ed,%rax
  802dae:	00 00 00 
  802db1:	ff d0                	callq  *%rax
  802db3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802db7:	ba 00 00 00 00       	mov    $0x0,%edx
  802dbc:	48 89 c6             	mov    %rax,%rsi
  802dbf:	bf 00 00 00 00       	mov    $0x0,%edi
  802dc4:	48 b8 2c 45 80 00 00 	movabs $0x80452c,%rax
  802dcb:	00 00 00 
  802dce:	ff d0                	callq  *%rax
  802dd0:	c9                   	leaveq 
  802dd1:	c3                   	retq   

0000000000802dd2 <open>:
  802dd2:	55                   	push   %rbp
  802dd3:	48 89 e5             	mov    %rsp,%rbp
  802dd6:	48 83 ec 20          	sub    $0x20,%rsp
  802dda:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802dde:	89 75 e4             	mov    %esi,-0x1c(%rbp)
  802de1:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802de5:	48 89 c7             	mov    %rax,%rdi
  802de8:	48 b8 6b 15 80 00 00 	movabs $0x80156b,%rax
  802def:	00 00 00 
  802df2:	ff d0                	callq  *%rax
  802df4:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  802df9:	7e 0a                	jle    802e05 <open+0x33>
  802dfb:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  802e00:	e9 a5 00 00 00       	jmpq   802eaa <open+0xd8>
  802e05:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  802e09:	48 89 c7             	mov    %rax,%rdi
  802e0c:	48 b8 32 24 80 00 00 	movabs $0x802432,%rax
  802e13:	00 00 00 
  802e16:	ff d0                	callq  *%rax
  802e18:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802e1b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802e1f:	79 08                	jns    802e29 <open+0x57>
  802e21:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802e24:	e9 81 00 00 00       	jmpq   802eaa <open+0xd8>
  802e29:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802e2d:	48 89 c6             	mov    %rax,%rsi
  802e30:	48 bf 00 90 80 00 00 	movabs $0x809000,%rdi
  802e37:	00 00 00 
  802e3a:	48 b8 d7 15 80 00 00 	movabs $0x8015d7,%rax
  802e41:	00 00 00 
  802e44:	ff d0                	callq  *%rax
  802e46:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  802e4d:	00 00 00 
  802e50:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  802e53:	89 90 00 04 00 00    	mov    %edx,0x400(%rax)
  802e59:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802e5d:	48 89 c6             	mov    %rax,%rsi
  802e60:	bf 01 00 00 00       	mov    $0x1,%edi
  802e65:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  802e6c:	00 00 00 
  802e6f:	ff d0                	callq  *%rax
  802e71:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802e74:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802e78:	79 1d                	jns    802e97 <open+0xc5>
  802e7a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802e7e:	be 00 00 00 00       	mov    $0x0,%esi
  802e83:	48 89 c7             	mov    %rax,%rdi
  802e86:	48 b8 5a 25 80 00 00 	movabs $0x80255a,%rax
  802e8d:	00 00 00 
  802e90:	ff d0                	callq  *%rax
  802e92:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802e95:	eb 13                	jmp    802eaa <open+0xd8>
  802e97:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  802e9b:	48 89 c7             	mov    %rax,%rdi
  802e9e:	48 b8 e4 23 80 00 00 	movabs $0x8023e4,%rax
  802ea5:	00 00 00 
  802ea8:	ff d0                	callq  *%rax
  802eaa:	c9                   	leaveq 
  802eab:	c3                   	retq   

0000000000802eac <devfile_flush>:
  802eac:	55                   	push   %rbp
  802ead:	48 89 e5             	mov    %rsp,%rbp
  802eb0:	48 83 ec 10          	sub    $0x10,%rsp
  802eb4:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  802eb8:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  802ebc:	8b 50 0c             	mov    0xc(%rax),%edx
  802ebf:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  802ec6:	00 00 00 
  802ec9:	89 10                	mov    %edx,(%rax)
  802ecb:	be 00 00 00 00       	mov    $0x0,%esi
  802ed0:	bf 06 00 00 00       	mov    $0x6,%edi
  802ed5:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  802edc:	00 00 00 
  802edf:	ff d0                	callq  *%rax
  802ee1:	c9                   	leaveq 
  802ee2:	c3                   	retq   

0000000000802ee3 <devfile_read>:
  802ee3:	55                   	push   %rbp
  802ee4:	48 89 e5             	mov    %rsp,%rbp
  802ee7:	48 83 ec 30          	sub    $0x30,%rsp
  802eeb:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  802eef:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  802ef3:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  802ef7:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  802efb:	8b 50 0c             	mov    0xc(%rax),%edx
  802efe:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  802f05:	00 00 00 
  802f08:	89 10                	mov    %edx,(%rax)
  802f0a:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  802f11:	00 00 00 
  802f14:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  802f18:	48 89 50 08          	mov    %rdx,0x8(%rax)
  802f1c:	be 00 00 00 00       	mov    $0x0,%esi
  802f21:	bf 03 00 00 00       	mov    $0x3,%edi
  802f26:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  802f2d:	00 00 00 
  802f30:	ff d0                	callq  *%rax
  802f32:	89 45 fc             	mov    %eax,-0x4(%rbp)
  802f35:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  802f39:	79 08                	jns    802f43 <devfile_read+0x60>
  802f3b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802f3e:	e9 a4 00 00 00       	jmpq   802fe7 <devfile_read+0x104>
  802f43:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802f46:	48 98                	cltq   
  802f48:	48 3b 45 d8          	cmp    -0x28(%rbp),%rax
  802f4c:	76 35                	jbe    802f83 <devfile_read+0xa0>
  802f4e:	48 b9 f6 4e 80 00 00 	movabs $0x804ef6,%rcx
  802f55:	00 00 00 
  802f58:	48 ba fd 4e 80 00 00 	movabs $0x804efd,%rdx
  802f5f:	00 00 00 
  802f62:	be 89 00 00 00       	mov    $0x89,%esi
  802f67:	48 bf 12 4f 80 00 00 	movabs $0x804f12,%rdi
  802f6e:	00 00 00 
  802f71:	b8 00 00 00 00       	mov    $0x0,%eax
  802f76:	49 b8 e9 07 80 00 00 	movabs $0x8007e9,%r8
  802f7d:	00 00 00 
  802f80:	41 ff d0             	callq  *%r8
  802f83:	81 7d fc 00 10 00 00 	cmpl   $0x1000,-0x4(%rbp)
  802f8a:	7e 35                	jle    802fc1 <devfile_read+0xde>
  802f8c:	48 b9 20 4f 80 00 00 	movabs $0x804f20,%rcx
  802f93:	00 00 00 
  802f96:	48 ba fd 4e 80 00 00 	movabs $0x804efd,%rdx
  802f9d:	00 00 00 
  802fa0:	be 8a 00 00 00       	mov    $0x8a,%esi
  802fa5:	48 bf 12 4f 80 00 00 	movabs $0x804f12,%rdi
  802fac:	00 00 00 
  802faf:	b8 00 00 00 00       	mov    $0x0,%eax
  802fb4:	49 b8 e9 07 80 00 00 	movabs $0x8007e9,%r8
  802fbb:	00 00 00 
  802fbe:	41 ff d0             	callq  *%r8
  802fc1:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802fc4:	48 63 d0             	movslq %eax,%rdx
  802fc7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  802fcb:	48 be 00 90 80 00 00 	movabs $0x809000,%rsi
  802fd2:	00 00 00 
  802fd5:	48 89 c7             	mov    %rax,%rdi
  802fd8:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  802fdf:	00 00 00 
  802fe2:	ff d0                	callq  *%rax
  802fe4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  802fe7:	c9                   	leaveq 
  802fe8:	c3                   	retq   

0000000000802fe9 <devfile_write>:
  802fe9:	55                   	push   %rbp
  802fea:	48 89 e5             	mov    %rsp,%rbp
  802fed:	48 83 ec 40          	sub    $0x40,%rsp
  802ff1:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  802ff5:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  802ff9:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  802ffd:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803001:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  803005:	48 c7 45 f0 f4 0f 00 	movq   $0xff4,-0x10(%rbp)
  80300c:	00 
  80300d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803011:	48 39 45 f8          	cmp    %rax,-0x8(%rbp)
  803015:	48 0f 46 45 f8       	cmovbe -0x8(%rbp),%rax
  80301a:	48 89 45 c8          	mov    %rax,-0x38(%rbp)
  80301e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803022:	8b 50 0c             	mov    0xc(%rax),%edx
  803025:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  80302c:	00 00 00 
  80302f:	89 10                	mov    %edx,(%rax)
  803031:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  803038:	00 00 00 
  80303b:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  80303f:	48 89 50 08          	mov    %rdx,0x8(%rax)
  803043:	48 8b 55 c8          	mov    -0x38(%rbp),%rdx
  803047:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80304b:	48 89 c6             	mov    %rax,%rsi
  80304e:	48 bf 10 90 80 00 00 	movabs $0x809010,%rdi
  803055:	00 00 00 
  803058:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  80305f:	00 00 00 
  803062:	ff d0                	callq  *%rax
  803064:	be 00 00 00 00       	mov    $0x0,%esi
  803069:	bf 04 00 00 00       	mov    $0x4,%edi
  80306e:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  803075:	00 00 00 
  803078:	ff d0                	callq  *%rax
  80307a:	89 45 ec             	mov    %eax,-0x14(%rbp)
  80307d:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803081:	79 05                	jns    803088 <devfile_write+0x9f>
  803083:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803086:	eb 43                	jmp    8030cb <devfile_write+0xe2>
  803088:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80308b:	48 98                	cltq   
  80308d:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  803091:	76 35                	jbe    8030c8 <devfile_write+0xdf>
  803093:	48 b9 f6 4e 80 00 00 	movabs $0x804ef6,%rcx
  80309a:	00 00 00 
  80309d:	48 ba fd 4e 80 00 00 	movabs $0x804efd,%rdx
  8030a4:	00 00 00 
  8030a7:	be a8 00 00 00       	mov    $0xa8,%esi
  8030ac:	48 bf 12 4f 80 00 00 	movabs $0x804f12,%rdi
  8030b3:	00 00 00 
  8030b6:	b8 00 00 00 00       	mov    $0x0,%eax
  8030bb:	49 b8 e9 07 80 00 00 	movabs $0x8007e9,%r8
  8030c2:	00 00 00 
  8030c5:	41 ff d0             	callq  *%r8
  8030c8:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8030cb:	c9                   	leaveq 
  8030cc:	c3                   	retq   

00000000008030cd <devfile_stat>:
  8030cd:	55                   	push   %rbp
  8030ce:	48 89 e5             	mov    %rsp,%rbp
  8030d1:	48 83 ec 20          	sub    $0x20,%rsp
  8030d5:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8030d9:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8030dd:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8030e1:	8b 50 0c             	mov    0xc(%rax),%edx
  8030e4:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  8030eb:	00 00 00 
  8030ee:	89 10                	mov    %edx,(%rax)
  8030f0:	be 00 00 00 00       	mov    $0x0,%esi
  8030f5:	bf 05 00 00 00       	mov    $0x5,%edi
  8030fa:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  803101:	00 00 00 
  803104:	ff d0                	callq  *%rax
  803106:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803109:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80310d:	79 05                	jns    803114 <devfile_stat+0x47>
  80310f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803112:	eb 56                	jmp    80316a <devfile_stat+0x9d>
  803114:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803118:	48 be 00 90 80 00 00 	movabs $0x809000,%rsi
  80311f:	00 00 00 
  803122:	48 89 c7             	mov    %rax,%rdi
  803125:	48 b8 d7 15 80 00 00 	movabs $0x8015d7,%rax
  80312c:	00 00 00 
  80312f:	ff d0                	callq  *%rax
  803131:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  803138:	00 00 00 
  80313b:	8b 90 80 00 00 00    	mov    0x80(%rax),%edx
  803141:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803145:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  80314b:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  803152:	00 00 00 
  803155:	8b 90 84 00 00 00    	mov    0x84(%rax),%edx
  80315b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80315f:	89 90 84 00 00 00    	mov    %edx,0x84(%rax)
  803165:	b8 00 00 00 00       	mov    $0x0,%eax
  80316a:	c9                   	leaveq 
  80316b:	c3                   	retq   

000000000080316c <devfile_trunc>:
  80316c:	55                   	push   %rbp
  80316d:	48 89 e5             	mov    %rsp,%rbp
  803170:	48 83 ec 10          	sub    $0x10,%rsp
  803174:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803178:	89 75 f4             	mov    %esi,-0xc(%rbp)
  80317b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80317f:	8b 50 0c             	mov    0xc(%rax),%edx
  803182:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  803189:	00 00 00 
  80318c:	89 10                	mov    %edx,(%rax)
  80318e:	48 b8 00 90 80 00 00 	movabs $0x809000,%rax
  803195:	00 00 00 
  803198:	8b 55 f4             	mov    -0xc(%rbp),%edx
  80319b:	89 50 04             	mov    %edx,0x4(%rax)
  80319e:	be 00 00 00 00       	mov    $0x0,%esi
  8031a3:	bf 02 00 00 00       	mov    $0x2,%edi
  8031a8:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  8031af:	00 00 00 
  8031b2:	ff d0                	callq  *%rax
  8031b4:	c9                   	leaveq 
  8031b5:	c3                   	retq   

00000000008031b6 <remove>:
  8031b6:	55                   	push   %rbp
  8031b7:	48 89 e5             	mov    %rsp,%rbp
  8031ba:	48 83 ec 10          	sub    $0x10,%rsp
  8031be:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8031c2:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8031c6:	48 89 c7             	mov    %rax,%rdi
  8031c9:	48 b8 6b 15 80 00 00 	movabs $0x80156b,%rax
  8031d0:	00 00 00 
  8031d3:	ff d0                	callq  *%rax
  8031d5:	3d ff 03 00 00       	cmp    $0x3ff,%eax
  8031da:	7e 07                	jle    8031e3 <remove+0x2d>
  8031dc:	b8 f3 ff ff ff       	mov    $0xfffffff3,%eax
  8031e1:	eb 33                	jmp    803216 <remove+0x60>
  8031e3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8031e7:	48 89 c6             	mov    %rax,%rsi
  8031ea:	48 bf 00 90 80 00 00 	movabs $0x809000,%rdi
  8031f1:	00 00 00 
  8031f4:	48 b8 d7 15 80 00 00 	movabs $0x8015d7,%rax
  8031fb:	00 00 00 
  8031fe:	ff d0                	callq  *%rax
  803200:	be 00 00 00 00       	mov    $0x0,%esi
  803205:	bf 07 00 00 00       	mov    $0x7,%edi
  80320a:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  803211:	00 00 00 
  803214:	ff d0                	callq  *%rax
  803216:	c9                   	leaveq 
  803217:	c3                   	retq   

0000000000803218 <sync>:
  803218:	55                   	push   %rbp
  803219:	48 89 e5             	mov    %rsp,%rbp
  80321c:	be 00 00 00 00       	mov    $0x0,%esi
  803221:	bf 08 00 00 00       	mov    $0x8,%edi
  803226:	48 b8 4b 2d 80 00 00 	movabs $0x802d4b,%rax
  80322d:	00 00 00 
  803230:	ff d0                	callq  *%rax
  803232:	5d                   	pop    %rbp
  803233:	c3                   	retq   

0000000000803234 <copy>:
  803234:	55                   	push   %rbp
  803235:	48 89 e5             	mov    %rsp,%rbp
  803238:	48 81 ec 20 02 00 00 	sub    $0x220,%rsp
  80323f:	48 89 bd e8 fd ff ff 	mov    %rdi,-0x218(%rbp)
  803246:	48 89 b5 e0 fd ff ff 	mov    %rsi,-0x220(%rbp)
  80324d:	48 8b 85 e8 fd ff ff 	mov    -0x218(%rbp),%rax
  803254:	be 00 00 00 00       	mov    $0x0,%esi
  803259:	48 89 c7             	mov    %rax,%rdi
  80325c:	48 b8 d2 2d 80 00 00 	movabs $0x802dd2,%rax
  803263:	00 00 00 
  803266:	ff d0                	callq  *%rax
  803268:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80326b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80326f:	79 28                	jns    803299 <copy+0x65>
  803271:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803274:	89 c6                	mov    %eax,%esi
  803276:	48 bf 2c 4f 80 00 00 	movabs $0x804f2c,%rdi
  80327d:	00 00 00 
  803280:	b8 00 00 00 00       	mov    $0x0,%eax
  803285:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  80328c:	00 00 00 
  80328f:	ff d2                	callq  *%rdx
  803291:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803294:	e9 74 01 00 00       	jmpq   80340d <copy+0x1d9>
  803299:	48 8b 85 e0 fd ff ff 	mov    -0x220(%rbp),%rax
  8032a0:	be 01 01 00 00       	mov    $0x101,%esi
  8032a5:	48 89 c7             	mov    %rax,%rdi
  8032a8:	48 b8 d2 2d 80 00 00 	movabs $0x802dd2,%rax
  8032af:	00 00 00 
  8032b2:	ff d0                	callq  *%rax
  8032b4:	89 45 f8             	mov    %eax,-0x8(%rbp)
  8032b7:	83 7d f8 00          	cmpl   $0x0,-0x8(%rbp)
  8032bb:	79 39                	jns    8032f6 <copy+0xc2>
  8032bd:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8032c0:	89 c6                	mov    %eax,%esi
  8032c2:	48 bf 42 4f 80 00 00 	movabs $0x804f42,%rdi
  8032c9:	00 00 00 
  8032cc:	b8 00 00 00 00       	mov    $0x0,%eax
  8032d1:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  8032d8:	00 00 00 
  8032db:	ff d2                	callq  *%rdx
  8032dd:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8032e0:	89 c7                	mov    %eax,%edi
  8032e2:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  8032e9:	00 00 00 
  8032ec:	ff d0                	callq  *%rax
  8032ee:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8032f1:	e9 17 01 00 00       	jmpq   80340d <copy+0x1d9>
  8032f6:	eb 74                	jmp    80336c <copy+0x138>
  8032f8:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8032fb:	48 63 d0             	movslq %eax,%rdx
  8032fe:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  803305:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803308:	48 89 ce             	mov    %rcx,%rsi
  80330b:	89 c7                	mov    %eax,%edi
  80330d:	48 b8 46 2a 80 00 00 	movabs $0x802a46,%rax
  803314:	00 00 00 
  803317:	ff d0                	callq  *%rax
  803319:	89 45 f0             	mov    %eax,-0x10(%rbp)
  80331c:	83 7d f0 00          	cmpl   $0x0,-0x10(%rbp)
  803320:	79 4a                	jns    80336c <copy+0x138>
  803322:	8b 45 f0             	mov    -0x10(%rbp),%eax
  803325:	89 c6                	mov    %eax,%esi
  803327:	48 bf 5c 4f 80 00 00 	movabs $0x804f5c,%rdi
  80332e:	00 00 00 
  803331:	b8 00 00 00 00       	mov    $0x0,%eax
  803336:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  80333d:	00 00 00 
  803340:	ff d2                	callq  *%rdx
  803342:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803345:	89 c7                	mov    %eax,%edi
  803347:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  80334e:	00 00 00 
  803351:	ff d0                	callq  *%rax
  803353:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803356:	89 c7                	mov    %eax,%edi
  803358:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  80335f:	00 00 00 
  803362:	ff d0                	callq  *%rax
  803364:	8b 45 f0             	mov    -0x10(%rbp),%eax
  803367:	e9 a1 00 00 00       	jmpq   80340d <copy+0x1d9>
  80336c:	48 8d 8d f0 fd ff ff 	lea    -0x210(%rbp),%rcx
  803373:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803376:	ba 00 02 00 00       	mov    $0x200,%edx
  80337b:	48 89 ce             	mov    %rcx,%rsi
  80337e:	89 c7                	mov    %eax,%edi
  803380:	48 b8 fc 28 80 00 00 	movabs $0x8028fc,%rax
  803387:	00 00 00 
  80338a:	ff d0                	callq  *%rax
  80338c:	89 45 f4             	mov    %eax,-0xc(%rbp)
  80338f:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  803393:	0f 8f 5f ff ff ff    	jg     8032f8 <copy+0xc4>
  803399:	83 7d f4 00          	cmpl   $0x0,-0xc(%rbp)
  80339d:	79 47                	jns    8033e6 <copy+0x1b2>
  80339f:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8033a2:	89 c6                	mov    %eax,%esi
  8033a4:	48 bf 6f 4f 80 00 00 	movabs $0x804f6f,%rdi
  8033ab:	00 00 00 
  8033ae:	b8 00 00 00 00       	mov    $0x0,%eax
  8033b3:	48 ba 22 0a 80 00 00 	movabs $0x800a22,%rdx
  8033ba:	00 00 00 
  8033bd:	ff d2                	callq  *%rdx
  8033bf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033c2:	89 c7                	mov    %eax,%edi
  8033c4:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  8033cb:	00 00 00 
  8033ce:	ff d0                	callq  *%rax
  8033d0:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8033d3:	89 c7                	mov    %eax,%edi
  8033d5:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  8033dc:	00 00 00 
  8033df:	ff d0                	callq  *%rax
  8033e1:	8b 45 f4             	mov    -0xc(%rbp),%eax
  8033e4:	eb 27                	jmp    80340d <copy+0x1d9>
  8033e6:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8033e9:	89 c7                	mov    %eax,%edi
  8033eb:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  8033f2:	00 00 00 
  8033f5:	ff d0                	callq  *%rax
  8033f7:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8033fa:	89 c7                	mov    %eax,%edi
  8033fc:	48 b8 da 26 80 00 00 	movabs $0x8026da,%rax
  803403:	00 00 00 
  803406:	ff d0                	callq  *%rax
  803408:	b8 00 00 00 00       	mov    $0x0,%eax
  80340d:	c9                   	leaveq 
  80340e:	c3                   	retq   

000000000080340f <fd2sockid>:
  80340f:	55                   	push   %rbp
  803410:	48 89 e5             	mov    %rsp,%rbp
  803413:	48 83 ec 20          	sub    $0x20,%rsp
  803417:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80341a:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  80341e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803421:	48 89 d6             	mov    %rdx,%rsi
  803424:	89 c7                	mov    %eax,%edi
  803426:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  80342d:	00 00 00 
  803430:	ff d0                	callq  *%rax
  803432:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803435:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803439:	79 05                	jns    803440 <fd2sockid+0x31>
  80343b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80343e:	eb 24                	jmp    803464 <fd2sockid+0x55>
  803440:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803444:	8b 10                	mov    (%rax),%edx
  803446:	48 b8 a0 70 80 00 00 	movabs $0x8070a0,%rax
  80344d:	00 00 00 
  803450:	8b 00                	mov    (%rax),%eax
  803452:	39 c2                	cmp    %eax,%edx
  803454:	74 07                	je     80345d <fd2sockid+0x4e>
  803456:	b8 f0 ff ff ff       	mov    $0xfffffff0,%eax
  80345b:	eb 07                	jmp    803464 <fd2sockid+0x55>
  80345d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803461:	8b 40 0c             	mov    0xc(%rax),%eax
  803464:	c9                   	leaveq 
  803465:	c3                   	retq   

0000000000803466 <alloc_sockfd>:
  803466:	55                   	push   %rbp
  803467:	48 89 e5             	mov    %rsp,%rbp
  80346a:	48 83 ec 20          	sub    $0x20,%rsp
  80346e:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803471:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  803475:	48 89 c7             	mov    %rax,%rdi
  803478:	48 b8 32 24 80 00 00 	movabs $0x802432,%rax
  80347f:	00 00 00 
  803482:	ff d0                	callq  *%rax
  803484:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803487:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80348b:	78 26                	js     8034b3 <alloc_sockfd+0x4d>
  80348d:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803491:	ba 07 04 00 00       	mov    $0x407,%edx
  803496:	48 89 c6             	mov    %rax,%rsi
  803499:	bf 00 00 00 00       	mov    $0x0,%edi
  80349e:	48 b8 06 1f 80 00 00 	movabs $0x801f06,%rax
  8034a5:	00 00 00 
  8034a8:	ff d0                	callq  *%rax
  8034aa:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8034ad:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8034b1:	79 16                	jns    8034c9 <alloc_sockfd+0x63>
  8034b3:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8034b6:	89 c7                	mov    %eax,%edi
  8034b8:	48 b8 73 39 80 00 00 	movabs $0x803973,%rax
  8034bf:	00 00 00 
  8034c2:	ff d0                	callq  *%rax
  8034c4:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8034c7:	eb 3a                	jmp    803503 <alloc_sockfd+0x9d>
  8034c9:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8034cd:	48 ba a0 70 80 00 00 	movabs $0x8070a0,%rdx
  8034d4:	00 00 00 
  8034d7:	8b 12                	mov    (%rdx),%edx
  8034d9:	89 10                	mov    %edx,(%rax)
  8034db:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8034df:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  8034e6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8034ea:	8b 55 ec             	mov    -0x14(%rbp),%edx
  8034ed:	89 50 0c             	mov    %edx,0xc(%rax)
  8034f0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8034f4:	48 89 c7             	mov    %rax,%rdi
  8034f7:	48 b8 e4 23 80 00 00 	movabs $0x8023e4,%rax
  8034fe:	00 00 00 
  803501:	ff d0                	callq  *%rax
  803503:	c9                   	leaveq 
  803504:	c3                   	retq   

0000000000803505 <accept>:
  803505:	55                   	push   %rbp
  803506:	48 89 e5             	mov    %rsp,%rbp
  803509:	48 83 ec 30          	sub    $0x30,%rsp
  80350d:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803510:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803514:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  803518:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80351b:	89 c7                	mov    %eax,%edi
  80351d:	48 b8 0f 34 80 00 00 	movabs $0x80340f,%rax
  803524:	00 00 00 
  803527:	ff d0                	callq  *%rax
  803529:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80352c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803530:	79 05                	jns    803537 <accept+0x32>
  803532:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803535:	eb 3b                	jmp    803572 <accept+0x6d>
  803537:	48 8b 55 d8          	mov    -0x28(%rbp),%rdx
  80353b:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  80353f:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803542:	48 89 ce             	mov    %rcx,%rsi
  803545:	89 c7                	mov    %eax,%edi
  803547:	48 b8 50 38 80 00 00 	movabs $0x803850,%rax
  80354e:	00 00 00 
  803551:	ff d0                	callq  *%rax
  803553:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803556:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80355a:	79 05                	jns    803561 <accept+0x5c>
  80355c:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80355f:	eb 11                	jmp    803572 <accept+0x6d>
  803561:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803564:	89 c7                	mov    %eax,%edi
  803566:	48 b8 66 34 80 00 00 	movabs $0x803466,%rax
  80356d:	00 00 00 
  803570:	ff d0                	callq  *%rax
  803572:	c9                   	leaveq 
  803573:	c3                   	retq   

0000000000803574 <bind>:
  803574:	55                   	push   %rbp
  803575:	48 89 e5             	mov    %rsp,%rbp
  803578:	48 83 ec 20          	sub    $0x20,%rsp
  80357c:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80357f:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803583:	89 55 e8             	mov    %edx,-0x18(%rbp)
  803586:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803589:	89 c7                	mov    %eax,%edi
  80358b:	48 b8 0f 34 80 00 00 	movabs $0x80340f,%rax
  803592:	00 00 00 
  803595:	ff d0                	callq  *%rax
  803597:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80359a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80359e:	79 05                	jns    8035a5 <bind+0x31>
  8035a0:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8035a3:	eb 1b                	jmp    8035c0 <bind+0x4c>
  8035a5:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8035a8:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  8035ac:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8035af:	48 89 ce             	mov    %rcx,%rsi
  8035b2:	89 c7                	mov    %eax,%edi
  8035b4:	48 b8 cf 38 80 00 00 	movabs $0x8038cf,%rax
  8035bb:	00 00 00 
  8035be:	ff d0                	callq  *%rax
  8035c0:	c9                   	leaveq 
  8035c1:	c3                   	retq   

00000000008035c2 <shutdown>:
  8035c2:	55                   	push   %rbp
  8035c3:	48 89 e5             	mov    %rsp,%rbp
  8035c6:	48 83 ec 20          	sub    $0x20,%rsp
  8035ca:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8035cd:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8035d0:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8035d3:	89 c7                	mov    %eax,%edi
  8035d5:	48 b8 0f 34 80 00 00 	movabs $0x80340f,%rax
  8035dc:	00 00 00 
  8035df:	ff d0                	callq  *%rax
  8035e1:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8035e4:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8035e8:	79 05                	jns    8035ef <shutdown+0x2d>
  8035ea:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8035ed:	eb 16                	jmp    803605 <shutdown+0x43>
  8035ef:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8035f2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8035f5:	89 d6                	mov    %edx,%esi
  8035f7:	89 c7                	mov    %eax,%edi
  8035f9:	48 b8 33 39 80 00 00 	movabs $0x803933,%rax
  803600:	00 00 00 
  803603:	ff d0                	callq  *%rax
  803605:	c9                   	leaveq 
  803606:	c3                   	retq   

0000000000803607 <devsock_close>:
  803607:	55                   	push   %rbp
  803608:	48 89 e5             	mov    %rsp,%rbp
  80360b:	48 83 ec 10          	sub    $0x10,%rsp
  80360f:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803613:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803617:	48 89 c7             	mov    %rax,%rdi
  80361a:	48 b8 f5 46 80 00 00 	movabs $0x8046f5,%rax
  803621:	00 00 00 
  803624:	ff d0                	callq  *%rax
  803626:	83 f8 01             	cmp    $0x1,%eax
  803629:	75 17                	jne    803642 <devsock_close+0x3b>
  80362b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80362f:	8b 40 0c             	mov    0xc(%rax),%eax
  803632:	89 c7                	mov    %eax,%edi
  803634:	48 b8 73 39 80 00 00 	movabs $0x803973,%rax
  80363b:	00 00 00 
  80363e:	ff d0                	callq  *%rax
  803640:	eb 05                	jmp    803647 <devsock_close+0x40>
  803642:	b8 00 00 00 00       	mov    $0x0,%eax
  803647:	c9                   	leaveq 
  803648:	c3                   	retq   

0000000000803649 <connect>:
  803649:	55                   	push   %rbp
  80364a:	48 89 e5             	mov    %rsp,%rbp
  80364d:	48 83 ec 20          	sub    $0x20,%rsp
  803651:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803654:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803658:	89 55 e8             	mov    %edx,-0x18(%rbp)
  80365b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80365e:	89 c7                	mov    %eax,%edi
  803660:	48 b8 0f 34 80 00 00 	movabs $0x80340f,%rax
  803667:	00 00 00 
  80366a:	ff d0                	callq  *%rax
  80366c:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80366f:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803673:	79 05                	jns    80367a <connect+0x31>
  803675:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803678:	eb 1b                	jmp    803695 <connect+0x4c>
  80367a:	8b 55 e8             	mov    -0x18(%rbp),%edx
  80367d:	48 8b 4d e0          	mov    -0x20(%rbp),%rcx
  803681:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803684:	48 89 ce             	mov    %rcx,%rsi
  803687:	89 c7                	mov    %eax,%edi
  803689:	48 b8 a0 39 80 00 00 	movabs $0x8039a0,%rax
  803690:	00 00 00 
  803693:	ff d0                	callq  *%rax
  803695:	c9                   	leaveq 
  803696:	c3                   	retq   

0000000000803697 <listen>:
  803697:	55                   	push   %rbp
  803698:	48 89 e5             	mov    %rsp,%rbp
  80369b:	48 83 ec 20          	sub    $0x20,%rsp
  80369f:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8036a2:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8036a5:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8036a8:	89 c7                	mov    %eax,%edi
  8036aa:	48 b8 0f 34 80 00 00 	movabs $0x80340f,%rax
  8036b1:	00 00 00 
  8036b4:	ff d0                	callq  *%rax
  8036b6:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8036b9:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8036bd:	79 05                	jns    8036c4 <listen+0x2d>
  8036bf:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8036c2:	eb 16                	jmp    8036da <listen+0x43>
  8036c4:	8b 55 e8             	mov    -0x18(%rbp),%edx
  8036c7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8036ca:	89 d6                	mov    %edx,%esi
  8036cc:	89 c7                	mov    %eax,%edi
  8036ce:	48 b8 04 3a 80 00 00 	movabs $0x803a04,%rax
  8036d5:	00 00 00 
  8036d8:	ff d0                	callq  *%rax
  8036da:	c9                   	leaveq 
  8036db:	c3                   	retq   

00000000008036dc <devsock_read>:
  8036dc:	55                   	push   %rbp
  8036dd:	48 89 e5             	mov    %rsp,%rbp
  8036e0:	48 83 ec 20          	sub    $0x20,%rsp
  8036e4:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8036e8:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8036ec:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  8036f0:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8036f4:	89 c2                	mov    %eax,%edx
  8036f6:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8036fa:	8b 40 0c             	mov    0xc(%rax),%eax
  8036fd:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  803701:	b9 00 00 00 00       	mov    $0x0,%ecx
  803706:	89 c7                	mov    %eax,%edi
  803708:	48 b8 44 3a 80 00 00 	movabs $0x803a44,%rax
  80370f:	00 00 00 
  803712:	ff d0                	callq  *%rax
  803714:	c9                   	leaveq 
  803715:	c3                   	retq   

0000000000803716 <devsock_write>:
  803716:	55                   	push   %rbp
  803717:	48 89 e5             	mov    %rsp,%rbp
  80371a:	48 83 ec 20          	sub    $0x20,%rsp
  80371e:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  803722:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803726:	48 89 55 e8          	mov    %rdx,-0x18(%rbp)
  80372a:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80372e:	89 c2                	mov    %eax,%edx
  803730:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803734:	8b 40 0c             	mov    0xc(%rax),%eax
  803737:	48 8b 75 f0          	mov    -0x10(%rbp),%rsi
  80373b:	b9 00 00 00 00       	mov    $0x0,%ecx
  803740:	89 c7                	mov    %eax,%edi
  803742:	48 b8 10 3b 80 00 00 	movabs $0x803b10,%rax
  803749:	00 00 00 
  80374c:	ff d0                	callq  *%rax
  80374e:	c9                   	leaveq 
  80374f:	c3                   	retq   

0000000000803750 <devsock_stat>:
  803750:	55                   	push   %rbp
  803751:	48 89 e5             	mov    %rsp,%rbp
  803754:	48 83 ec 10          	sub    $0x10,%rsp
  803758:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  80375c:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803760:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803764:	48 be 8a 4f 80 00 00 	movabs $0x804f8a,%rsi
  80376b:	00 00 00 
  80376e:	48 89 c7             	mov    %rax,%rdi
  803771:	48 b8 d7 15 80 00 00 	movabs $0x8015d7,%rax
  803778:	00 00 00 
  80377b:	ff d0                	callq  *%rax
  80377d:	b8 00 00 00 00       	mov    $0x0,%eax
  803782:	c9                   	leaveq 
  803783:	c3                   	retq   

0000000000803784 <socket>:
  803784:	55                   	push   %rbp
  803785:	48 89 e5             	mov    %rsp,%rbp
  803788:	48 83 ec 20          	sub    $0x20,%rsp
  80378c:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80378f:	89 75 e8             	mov    %esi,-0x18(%rbp)
  803792:	89 55 e4             	mov    %edx,-0x1c(%rbp)
  803795:	8b 55 e4             	mov    -0x1c(%rbp),%edx
  803798:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  80379b:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80379e:	89 ce                	mov    %ecx,%esi
  8037a0:	89 c7                	mov    %eax,%edi
  8037a2:	48 b8 c8 3b 80 00 00 	movabs $0x803bc8,%rax
  8037a9:	00 00 00 
  8037ac:	ff d0                	callq  *%rax
  8037ae:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8037b1:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8037b5:	79 05                	jns    8037bc <socket+0x38>
  8037b7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8037ba:	eb 11                	jmp    8037cd <socket+0x49>
  8037bc:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8037bf:	89 c7                	mov    %eax,%edi
  8037c1:	48 b8 66 34 80 00 00 	movabs $0x803466,%rax
  8037c8:	00 00 00 
  8037cb:	ff d0                	callq  *%rax
  8037cd:	c9                   	leaveq 
  8037ce:	c3                   	retq   

00000000008037cf <nsipc>:
  8037cf:	55                   	push   %rbp
  8037d0:	48 89 e5             	mov    %rsp,%rbp
  8037d3:	48 83 ec 10          	sub    $0x10,%rsp
  8037d7:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8037da:	48 b8 04 80 80 00 00 	movabs $0x808004,%rax
  8037e1:	00 00 00 
  8037e4:	8b 00                	mov    (%rax),%eax
  8037e6:	85 c0                	test   %eax,%eax
  8037e8:	75 1d                	jne    803807 <nsipc+0x38>
  8037ea:	bf 02 00 00 00       	mov    $0x2,%edi
  8037ef:	48 b8 83 46 80 00 00 	movabs $0x804683,%rax
  8037f6:	00 00 00 
  8037f9:	ff d0                	callq  *%rax
  8037fb:	48 ba 04 80 80 00 00 	movabs $0x808004,%rdx
  803802:	00 00 00 
  803805:	89 02                	mov    %eax,(%rdx)
  803807:	48 b8 04 80 80 00 00 	movabs $0x808004,%rax
  80380e:	00 00 00 
  803811:	8b 00                	mov    (%rax),%eax
  803813:	8b 75 fc             	mov    -0x4(%rbp),%esi
  803816:	b9 07 00 00 00       	mov    $0x7,%ecx
  80381b:	48 ba 00 b0 80 00 00 	movabs $0x80b000,%rdx
  803822:	00 00 00 
  803825:	89 c7                	mov    %eax,%edi
  803827:	48 b8 ed 45 80 00 00 	movabs $0x8045ed,%rax
  80382e:	00 00 00 
  803831:	ff d0                	callq  *%rax
  803833:	ba 00 00 00 00       	mov    $0x0,%edx
  803838:	be 00 00 00 00       	mov    $0x0,%esi
  80383d:	bf 00 00 00 00       	mov    $0x0,%edi
  803842:	48 b8 2c 45 80 00 00 	movabs $0x80452c,%rax
  803849:	00 00 00 
  80384c:	ff d0                	callq  *%rax
  80384e:	c9                   	leaveq 
  80384f:	c3                   	retq   

0000000000803850 <nsipc_accept>:
  803850:	55                   	push   %rbp
  803851:	48 89 e5             	mov    %rsp,%rbp
  803854:	48 83 ec 30          	sub    $0x30,%rsp
  803858:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80385b:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80385f:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  803863:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  80386a:	00 00 00 
  80386d:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803870:	89 10                	mov    %edx,(%rax)
  803872:	bf 01 00 00 00       	mov    $0x1,%edi
  803877:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  80387e:	00 00 00 
  803881:	ff d0                	callq  *%rax
  803883:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803886:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80388a:	78 3e                	js     8038ca <nsipc_accept+0x7a>
  80388c:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803893:	00 00 00 
  803896:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  80389a:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80389e:	8b 40 10             	mov    0x10(%rax),%eax
  8038a1:	89 c2                	mov    %eax,%edx
  8038a3:	48 8b 4d f0          	mov    -0x10(%rbp),%rcx
  8038a7:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  8038ab:	48 89 ce             	mov    %rcx,%rsi
  8038ae:	48 89 c7             	mov    %rax,%rdi
  8038b1:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  8038b8:	00 00 00 
  8038bb:	ff d0                	callq  *%rax
  8038bd:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8038c1:	8b 50 10             	mov    0x10(%rax),%edx
  8038c4:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8038c8:	89 10                	mov    %edx,(%rax)
  8038ca:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8038cd:	c9                   	leaveq 
  8038ce:	c3                   	retq   

00000000008038cf <nsipc_bind>:
  8038cf:	55                   	push   %rbp
  8038d0:	48 89 e5             	mov    %rsp,%rbp
  8038d3:	48 83 ec 10          	sub    $0x10,%rsp
  8038d7:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8038da:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8038de:	89 55 f8             	mov    %edx,-0x8(%rbp)
  8038e1:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  8038e8:	00 00 00 
  8038eb:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8038ee:	89 10                	mov    %edx,(%rax)
  8038f0:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8038f3:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8038f7:	48 89 c6             	mov    %rax,%rsi
  8038fa:	48 bf 04 b0 80 00 00 	movabs $0x80b004,%rdi
  803901:	00 00 00 
  803904:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  80390b:	00 00 00 
  80390e:	ff d0                	callq  *%rax
  803910:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803917:	00 00 00 
  80391a:	8b 55 f8             	mov    -0x8(%rbp),%edx
  80391d:	89 50 14             	mov    %edx,0x14(%rax)
  803920:	bf 02 00 00 00       	mov    $0x2,%edi
  803925:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  80392c:	00 00 00 
  80392f:	ff d0                	callq  *%rax
  803931:	c9                   	leaveq 
  803932:	c3                   	retq   

0000000000803933 <nsipc_shutdown>:
  803933:	55                   	push   %rbp
  803934:	48 89 e5             	mov    %rsp,%rbp
  803937:	48 83 ec 10          	sub    $0x10,%rsp
  80393b:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80393e:	89 75 f8             	mov    %esi,-0x8(%rbp)
  803941:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803948:	00 00 00 
  80394b:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80394e:	89 10                	mov    %edx,(%rax)
  803950:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803957:	00 00 00 
  80395a:	8b 55 f8             	mov    -0x8(%rbp),%edx
  80395d:	89 50 04             	mov    %edx,0x4(%rax)
  803960:	bf 03 00 00 00       	mov    $0x3,%edi
  803965:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  80396c:	00 00 00 
  80396f:	ff d0                	callq  *%rax
  803971:	c9                   	leaveq 
  803972:	c3                   	retq   

0000000000803973 <nsipc_close>:
  803973:	55                   	push   %rbp
  803974:	48 89 e5             	mov    %rsp,%rbp
  803977:	48 83 ec 10          	sub    $0x10,%rsp
  80397b:	89 7d fc             	mov    %edi,-0x4(%rbp)
  80397e:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803985:	00 00 00 
  803988:	8b 55 fc             	mov    -0x4(%rbp),%edx
  80398b:	89 10                	mov    %edx,(%rax)
  80398d:	bf 04 00 00 00       	mov    $0x4,%edi
  803992:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  803999:	00 00 00 
  80399c:	ff d0                	callq  *%rax
  80399e:	c9                   	leaveq 
  80399f:	c3                   	retq   

00000000008039a0 <nsipc_connect>:
  8039a0:	55                   	push   %rbp
  8039a1:	48 89 e5             	mov    %rsp,%rbp
  8039a4:	48 83 ec 10          	sub    $0x10,%rsp
  8039a8:	89 7d fc             	mov    %edi,-0x4(%rbp)
  8039ab:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  8039af:	89 55 f8             	mov    %edx,-0x8(%rbp)
  8039b2:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  8039b9:	00 00 00 
  8039bc:	8b 55 fc             	mov    -0x4(%rbp),%edx
  8039bf:	89 10                	mov    %edx,(%rax)
  8039c1:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8039c4:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8039c8:	48 89 c6             	mov    %rax,%rsi
  8039cb:	48 bf 04 b0 80 00 00 	movabs $0x80b004,%rdi
  8039d2:	00 00 00 
  8039d5:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  8039dc:	00 00 00 
  8039df:	ff d0                	callq  *%rax
  8039e1:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  8039e8:	00 00 00 
  8039eb:	8b 55 f8             	mov    -0x8(%rbp),%edx
  8039ee:	89 50 14             	mov    %edx,0x14(%rax)
  8039f1:	bf 05 00 00 00       	mov    $0x5,%edi
  8039f6:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  8039fd:	00 00 00 
  803a00:	ff d0                	callq  *%rax
  803a02:	c9                   	leaveq 
  803a03:	c3                   	retq   

0000000000803a04 <nsipc_listen>:
  803a04:	55                   	push   %rbp
  803a05:	48 89 e5             	mov    %rsp,%rbp
  803a08:	48 83 ec 10          	sub    $0x10,%rsp
  803a0c:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803a0f:	89 75 f8             	mov    %esi,-0x8(%rbp)
  803a12:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803a19:	00 00 00 
  803a1c:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803a1f:	89 10                	mov    %edx,(%rax)
  803a21:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803a28:	00 00 00 
  803a2b:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803a2e:	89 50 04             	mov    %edx,0x4(%rax)
  803a31:	bf 06 00 00 00       	mov    $0x6,%edi
  803a36:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  803a3d:	00 00 00 
  803a40:	ff d0                	callq  *%rax
  803a42:	c9                   	leaveq 
  803a43:	c3                   	retq   

0000000000803a44 <nsipc_recv>:
  803a44:	55                   	push   %rbp
  803a45:	48 89 e5             	mov    %rsp,%rbp
  803a48:	48 83 ec 30          	sub    $0x30,%rsp
  803a4c:	89 7d ec             	mov    %edi,-0x14(%rbp)
  803a4f:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  803a53:	89 55 e8             	mov    %edx,-0x18(%rbp)
  803a56:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  803a59:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803a60:	00 00 00 
  803a63:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803a66:	89 10                	mov    %edx,(%rax)
  803a68:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803a6f:	00 00 00 
  803a72:	8b 55 e8             	mov    -0x18(%rbp),%edx
  803a75:	89 50 04             	mov    %edx,0x4(%rax)
  803a78:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803a7f:	00 00 00 
  803a82:	8b 55 dc             	mov    -0x24(%rbp),%edx
  803a85:	89 50 08             	mov    %edx,0x8(%rax)
  803a88:	bf 07 00 00 00       	mov    $0x7,%edi
  803a8d:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  803a94:	00 00 00 
  803a97:	ff d0                	callq  *%rax
  803a99:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803a9c:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803aa0:	78 69                	js     803b0b <nsipc_recv+0xc7>
  803aa2:	81 7d fc 3f 06 00 00 	cmpl   $0x63f,-0x4(%rbp)
  803aa9:	7f 08                	jg     803ab3 <nsipc_recv+0x6f>
  803aab:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803aae:	3b 45 e8             	cmp    -0x18(%rbp),%eax
  803ab1:	7e 35                	jle    803ae8 <nsipc_recv+0xa4>
  803ab3:	48 b9 91 4f 80 00 00 	movabs $0x804f91,%rcx
  803aba:	00 00 00 
  803abd:	48 ba a6 4f 80 00 00 	movabs $0x804fa6,%rdx
  803ac4:	00 00 00 
  803ac7:	be 62 00 00 00       	mov    $0x62,%esi
  803acc:	48 bf bb 4f 80 00 00 	movabs $0x804fbb,%rdi
  803ad3:	00 00 00 
  803ad6:	b8 00 00 00 00       	mov    $0x0,%eax
  803adb:	49 b8 e9 07 80 00 00 	movabs $0x8007e9,%r8
  803ae2:	00 00 00 
  803ae5:	41 ff d0             	callq  *%r8
  803ae8:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803aeb:	48 63 d0             	movslq %eax,%rdx
  803aee:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803af2:	48 be 00 b0 80 00 00 	movabs $0x80b000,%rsi
  803af9:	00 00 00 
  803afc:	48 89 c7             	mov    %rax,%rdi
  803aff:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  803b06:	00 00 00 
  803b09:	ff d0                	callq  *%rax
  803b0b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803b0e:	c9                   	leaveq 
  803b0f:	c3                   	retq   

0000000000803b10 <nsipc_send>:
  803b10:	55                   	push   %rbp
  803b11:	48 89 e5             	mov    %rsp,%rbp
  803b14:	48 83 ec 20          	sub    $0x20,%rsp
  803b18:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803b1b:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  803b1f:	89 55 f8             	mov    %edx,-0x8(%rbp)
  803b22:	89 4d ec             	mov    %ecx,-0x14(%rbp)
  803b25:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803b2c:	00 00 00 
  803b2f:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803b32:	89 10                	mov    %edx,(%rax)
  803b34:	81 7d f8 3f 06 00 00 	cmpl   $0x63f,-0x8(%rbp)
  803b3b:	7e 35                	jle    803b72 <nsipc_send+0x62>
  803b3d:	48 b9 ca 4f 80 00 00 	movabs $0x804fca,%rcx
  803b44:	00 00 00 
  803b47:	48 ba a6 4f 80 00 00 	movabs $0x804fa6,%rdx
  803b4e:	00 00 00 
  803b51:	be 6d 00 00 00       	mov    $0x6d,%esi
  803b56:	48 bf bb 4f 80 00 00 	movabs $0x804fbb,%rdi
  803b5d:	00 00 00 
  803b60:	b8 00 00 00 00       	mov    $0x0,%eax
  803b65:	49 b8 e9 07 80 00 00 	movabs $0x8007e9,%r8
  803b6c:	00 00 00 
  803b6f:	41 ff d0             	callq  *%r8
  803b72:	8b 45 f8             	mov    -0x8(%rbp),%eax
  803b75:	48 63 d0             	movslq %eax,%rdx
  803b78:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803b7c:	48 89 c6             	mov    %rax,%rsi
  803b7f:	48 bf 0c b0 80 00 00 	movabs $0x80b00c,%rdi
  803b86:	00 00 00 
  803b89:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  803b90:	00 00 00 
  803b93:	ff d0                	callq  *%rax
  803b95:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803b9c:	00 00 00 
  803b9f:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803ba2:	89 50 04             	mov    %edx,0x4(%rax)
  803ba5:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803bac:	00 00 00 
  803baf:	8b 55 ec             	mov    -0x14(%rbp),%edx
  803bb2:	89 50 08             	mov    %edx,0x8(%rax)
  803bb5:	bf 08 00 00 00       	mov    $0x8,%edi
  803bba:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  803bc1:	00 00 00 
  803bc4:	ff d0                	callq  *%rax
  803bc6:	c9                   	leaveq 
  803bc7:	c3                   	retq   

0000000000803bc8 <nsipc_socket>:
  803bc8:	55                   	push   %rbp
  803bc9:	48 89 e5             	mov    %rsp,%rbp
  803bcc:	48 83 ec 10          	sub    $0x10,%rsp
  803bd0:	89 7d fc             	mov    %edi,-0x4(%rbp)
  803bd3:	89 75 f8             	mov    %esi,-0x8(%rbp)
  803bd6:	89 55 f4             	mov    %edx,-0xc(%rbp)
  803bd9:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803be0:	00 00 00 
  803be3:	8b 55 fc             	mov    -0x4(%rbp),%edx
  803be6:	89 10                	mov    %edx,(%rax)
  803be8:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803bef:	00 00 00 
  803bf2:	8b 55 f8             	mov    -0x8(%rbp),%edx
  803bf5:	89 50 04             	mov    %edx,0x4(%rax)
  803bf8:	48 b8 00 b0 80 00 00 	movabs $0x80b000,%rax
  803bff:	00 00 00 
  803c02:	8b 55 f4             	mov    -0xc(%rbp),%edx
  803c05:	89 50 08             	mov    %edx,0x8(%rax)
  803c08:	bf 09 00 00 00       	mov    $0x9,%edi
  803c0d:	48 b8 cf 37 80 00 00 	movabs $0x8037cf,%rax
  803c14:	00 00 00 
  803c17:	ff d0                	callq  *%rax
  803c19:	c9                   	leaveq 
  803c1a:	c3                   	retq   

0000000000803c1b <pipe>:
  803c1b:	55                   	push   %rbp
  803c1c:	48 89 e5             	mov    %rsp,%rbp
  803c1f:	53                   	push   %rbx
  803c20:	48 83 ec 38          	sub    $0x38,%rsp
  803c24:	48 89 7d c8          	mov    %rdi,-0x38(%rbp)
  803c28:	48 8d 45 d8          	lea    -0x28(%rbp),%rax
  803c2c:	48 89 c7             	mov    %rax,%rdi
  803c2f:	48 b8 32 24 80 00 00 	movabs $0x802432,%rax
  803c36:	00 00 00 
  803c39:	ff d0                	callq  *%rax
  803c3b:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803c3e:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803c42:	0f 88 bf 01 00 00    	js     803e07 <pipe+0x1ec>
  803c48:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803c4c:	ba 07 04 00 00       	mov    $0x407,%edx
  803c51:	48 89 c6             	mov    %rax,%rsi
  803c54:	bf 00 00 00 00       	mov    $0x0,%edi
  803c59:	48 b8 06 1f 80 00 00 	movabs $0x801f06,%rax
  803c60:	00 00 00 
  803c63:	ff d0                	callq  *%rax
  803c65:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803c68:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803c6c:	0f 88 95 01 00 00    	js     803e07 <pipe+0x1ec>
  803c72:	48 8d 45 d0          	lea    -0x30(%rbp),%rax
  803c76:	48 89 c7             	mov    %rax,%rdi
  803c79:	48 b8 32 24 80 00 00 	movabs $0x802432,%rax
  803c80:	00 00 00 
  803c83:	ff d0                	callq  *%rax
  803c85:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803c88:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803c8c:	0f 88 5d 01 00 00    	js     803def <pipe+0x1d4>
  803c92:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803c96:	ba 07 04 00 00       	mov    $0x407,%edx
  803c9b:	48 89 c6             	mov    %rax,%rsi
  803c9e:	bf 00 00 00 00       	mov    $0x0,%edi
  803ca3:	48 b8 06 1f 80 00 00 	movabs $0x801f06,%rax
  803caa:	00 00 00 
  803cad:	ff d0                	callq  *%rax
  803caf:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803cb2:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803cb6:	0f 88 33 01 00 00    	js     803def <pipe+0x1d4>
  803cbc:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803cc0:	48 89 c7             	mov    %rax,%rdi
  803cc3:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  803cca:	00 00 00 
  803ccd:	ff d0                	callq  *%rax
  803ccf:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  803cd3:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803cd7:	ba 07 04 00 00       	mov    $0x407,%edx
  803cdc:	48 89 c6             	mov    %rax,%rsi
  803cdf:	bf 00 00 00 00       	mov    $0x0,%edi
  803ce4:	48 b8 06 1f 80 00 00 	movabs $0x801f06,%rax
  803ceb:	00 00 00 
  803cee:	ff d0                	callq  *%rax
  803cf0:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803cf3:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803cf7:	79 05                	jns    803cfe <pipe+0xe3>
  803cf9:	e9 d9 00 00 00       	jmpq   803dd7 <pipe+0x1bc>
  803cfe:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803d02:	48 89 c7             	mov    %rax,%rdi
  803d05:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  803d0c:	00 00 00 
  803d0f:	ff d0                	callq  *%rax
  803d11:	48 89 c2             	mov    %rax,%rdx
  803d14:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803d18:	41 b8 07 04 00 00    	mov    $0x407,%r8d
  803d1e:	48 89 d1             	mov    %rdx,%rcx
  803d21:	ba 00 00 00 00       	mov    $0x0,%edx
  803d26:	48 89 c6             	mov    %rax,%rsi
  803d29:	bf 00 00 00 00       	mov    $0x0,%edi
  803d2e:	48 b8 56 1f 80 00 00 	movabs $0x801f56,%rax
  803d35:	00 00 00 
  803d38:	ff d0                	callq  *%rax
  803d3a:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803d3d:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  803d41:	79 1b                	jns    803d5e <pipe+0x143>
  803d43:	90                   	nop
  803d44:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  803d48:	48 89 c6             	mov    %rax,%rsi
  803d4b:	bf 00 00 00 00       	mov    $0x0,%edi
  803d50:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  803d57:	00 00 00 
  803d5a:	ff d0                	callq  *%rax
  803d5c:	eb 79                	jmp    803dd7 <pipe+0x1bc>
  803d5e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803d62:	48 ba e0 70 80 00 00 	movabs $0x8070e0,%rdx
  803d69:	00 00 00 
  803d6c:	8b 12                	mov    (%rdx),%edx
  803d6e:	89 10                	mov    %edx,(%rax)
  803d70:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803d74:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%rax)
  803d7b:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803d7f:	48 ba e0 70 80 00 00 	movabs $0x8070e0,%rdx
  803d86:	00 00 00 
  803d89:	8b 12                	mov    (%rdx),%edx
  803d8b:	89 10                	mov    %edx,(%rax)
  803d8d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803d91:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%rax)
  803d98:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803d9c:	48 89 c7             	mov    %rax,%rdi
  803d9f:	48 b8 e4 23 80 00 00 	movabs $0x8023e4,%rax
  803da6:	00 00 00 
  803da9:	ff d0                	callq  *%rax
  803dab:	89 c2                	mov    %eax,%edx
  803dad:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803db1:	89 10                	mov    %edx,(%rax)
  803db3:	48 8b 45 c8          	mov    -0x38(%rbp),%rax
  803db7:	48 8d 58 04          	lea    0x4(%rax),%rbx
  803dbb:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803dbf:	48 89 c7             	mov    %rax,%rdi
  803dc2:	48 b8 e4 23 80 00 00 	movabs $0x8023e4,%rax
  803dc9:	00 00 00 
  803dcc:	ff d0                	callq  *%rax
  803dce:	89 03                	mov    %eax,(%rbx)
  803dd0:	b8 00 00 00 00       	mov    $0x0,%eax
  803dd5:	eb 33                	jmp    803e0a <pipe+0x1ef>
  803dd7:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803ddb:	48 89 c6             	mov    %rax,%rsi
  803dde:	bf 00 00 00 00       	mov    $0x0,%edi
  803de3:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  803dea:	00 00 00 
  803ded:	ff d0                	callq  *%rax
  803def:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803df3:	48 89 c6             	mov    %rax,%rsi
  803df6:	bf 00 00 00 00       	mov    $0x0,%edi
  803dfb:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  803e02:	00 00 00 
  803e05:	ff d0                	callq  *%rax
  803e07:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803e0a:	48 83 c4 38          	add    $0x38,%rsp
  803e0e:	5b                   	pop    %rbx
  803e0f:	5d                   	pop    %rbp
  803e10:	c3                   	retq   

0000000000803e11 <_pipeisclosed>:
  803e11:	55                   	push   %rbp
  803e12:	48 89 e5             	mov    %rsp,%rbp
  803e15:	53                   	push   %rbx
  803e16:	48 83 ec 28          	sub    $0x28,%rsp
  803e1a:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803e1e:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803e22:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  803e29:	00 00 00 
  803e2c:	48 8b 00             	mov    (%rax),%rax
  803e2f:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803e35:	89 45 ec             	mov    %eax,-0x14(%rbp)
  803e38:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803e3c:	48 89 c7             	mov    %rax,%rdi
  803e3f:	48 b8 f5 46 80 00 00 	movabs $0x8046f5,%rax
  803e46:	00 00 00 
  803e49:	ff d0                	callq  *%rax
  803e4b:	89 c3                	mov    %eax,%ebx
  803e4d:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803e51:	48 89 c7             	mov    %rax,%rdi
  803e54:	48 b8 f5 46 80 00 00 	movabs $0x8046f5,%rax
  803e5b:	00 00 00 
  803e5e:	ff d0                	callq  *%rax
  803e60:	39 c3                	cmp    %eax,%ebx
  803e62:	0f 94 c0             	sete   %al
  803e65:	0f b6 c0             	movzbl %al,%eax
  803e68:	89 45 e8             	mov    %eax,-0x18(%rbp)
  803e6b:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  803e72:	00 00 00 
  803e75:	48 8b 00             	mov    (%rax),%rax
  803e78:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  803e7e:	89 45 e4             	mov    %eax,-0x1c(%rbp)
  803e81:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803e84:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803e87:	75 05                	jne    803e8e <_pipeisclosed+0x7d>
  803e89:	8b 45 e8             	mov    -0x18(%rbp),%eax
  803e8c:	eb 4f                	jmp    803edd <_pipeisclosed+0xcc>
  803e8e:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803e91:	3b 45 e4             	cmp    -0x1c(%rbp),%eax
  803e94:	74 42                	je     803ed8 <_pipeisclosed+0xc7>
  803e96:	83 7d e8 01          	cmpl   $0x1,-0x18(%rbp)
  803e9a:	75 3c                	jne    803ed8 <_pipeisclosed+0xc7>
  803e9c:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  803ea3:	00 00 00 
  803ea6:	48 8b 00             	mov    (%rax),%rax
  803ea9:	8b 90 d8 00 00 00    	mov    0xd8(%rax),%edx
  803eaf:	8b 4d e8             	mov    -0x18(%rbp),%ecx
  803eb2:	8b 45 ec             	mov    -0x14(%rbp),%eax
  803eb5:	89 c6                	mov    %eax,%esi
  803eb7:	48 bf db 4f 80 00 00 	movabs $0x804fdb,%rdi
  803ebe:	00 00 00 
  803ec1:	b8 00 00 00 00       	mov    $0x0,%eax
  803ec6:	49 b8 22 0a 80 00 00 	movabs $0x800a22,%r8
  803ecd:	00 00 00 
  803ed0:	41 ff d0             	callq  *%r8
  803ed3:	e9 4a ff ff ff       	jmpq   803e22 <_pipeisclosed+0x11>
  803ed8:	e9 45 ff ff ff       	jmpq   803e22 <_pipeisclosed+0x11>
  803edd:	48 83 c4 28          	add    $0x28,%rsp
  803ee1:	5b                   	pop    %rbx
  803ee2:	5d                   	pop    %rbp
  803ee3:	c3                   	retq   

0000000000803ee4 <pipeisclosed>:
  803ee4:	55                   	push   %rbp
  803ee5:	48 89 e5             	mov    %rsp,%rbp
  803ee8:	48 83 ec 30          	sub    $0x30,%rsp
  803eec:	89 7d dc             	mov    %edi,-0x24(%rbp)
  803eef:	48 8d 55 e8          	lea    -0x18(%rbp),%rdx
  803ef3:	8b 45 dc             	mov    -0x24(%rbp),%eax
  803ef6:	48 89 d6             	mov    %rdx,%rsi
  803ef9:	89 c7                	mov    %eax,%edi
  803efb:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  803f02:	00 00 00 
  803f05:	ff d0                	callq  *%rax
  803f07:	89 45 fc             	mov    %eax,-0x4(%rbp)
  803f0a:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  803f0e:	79 05                	jns    803f15 <pipeisclosed+0x31>
  803f10:	8b 45 fc             	mov    -0x4(%rbp),%eax
  803f13:	eb 31                	jmp    803f46 <pipeisclosed+0x62>
  803f15:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803f19:	48 89 c7             	mov    %rax,%rdi
  803f1c:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  803f23:	00 00 00 
  803f26:	ff d0                	callq  *%rax
  803f28:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803f2c:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  803f30:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803f34:	48 89 d6             	mov    %rdx,%rsi
  803f37:	48 89 c7             	mov    %rax,%rdi
  803f3a:	48 b8 11 3e 80 00 00 	movabs $0x803e11,%rax
  803f41:	00 00 00 
  803f44:	ff d0                	callq  *%rax
  803f46:	c9                   	leaveq 
  803f47:	c3                   	retq   

0000000000803f48 <devpipe_read>:
  803f48:	55                   	push   %rbp
  803f49:	48 89 e5             	mov    %rsp,%rbp
  803f4c:	48 83 ec 40          	sub    $0x40,%rsp
  803f50:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  803f54:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  803f58:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  803f5c:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803f60:	48 89 c7             	mov    %rax,%rdi
  803f63:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  803f6a:	00 00 00 
  803f6d:	ff d0                	callq  *%rax
  803f6f:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  803f73:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  803f77:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  803f7b:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  803f82:	00 
  803f83:	e9 92 00 00 00       	jmpq   80401a <devpipe_read+0xd2>
  803f88:	eb 41                	jmp    803fcb <devpipe_read+0x83>
  803f8a:	48 83 7d f8 00       	cmpq   $0x0,-0x8(%rbp)
  803f8f:	74 09                	je     803f9a <devpipe_read+0x52>
  803f91:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803f95:	e9 92 00 00 00       	jmpq   80402c <devpipe_read+0xe4>
  803f9a:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803f9e:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  803fa2:	48 89 d6             	mov    %rdx,%rsi
  803fa5:	48 89 c7             	mov    %rax,%rdi
  803fa8:	48 b8 11 3e 80 00 00 	movabs $0x803e11,%rax
  803faf:	00 00 00 
  803fb2:	ff d0                	callq  *%rax
  803fb4:	85 c0                	test   %eax,%eax
  803fb6:	74 07                	je     803fbf <devpipe_read+0x77>
  803fb8:	b8 00 00 00 00       	mov    $0x0,%eax
  803fbd:	eb 6d                	jmp    80402c <devpipe_read+0xe4>
  803fbf:	48 b8 c8 1e 80 00 00 	movabs $0x801ec8,%rax
  803fc6:	00 00 00 
  803fc9:	ff d0                	callq  *%rax
  803fcb:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803fcf:	8b 10                	mov    (%rax),%edx
  803fd1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803fd5:	8b 40 04             	mov    0x4(%rax),%eax
  803fd8:	39 c2                	cmp    %eax,%edx
  803fda:	74 ae                	je     803f8a <devpipe_read+0x42>
  803fdc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  803fe0:	48 8b 55 e8          	mov    -0x18(%rbp),%rdx
  803fe4:	48 8d 0c 02          	lea    (%rdx,%rax,1),%rcx
  803fe8:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  803fec:	8b 00                	mov    (%rax),%eax
  803fee:	99                   	cltd   
  803fef:	c1 ea 1b             	shr    $0x1b,%edx
  803ff2:	01 d0                	add    %edx,%eax
  803ff4:	83 e0 1f             	and    $0x1f,%eax
  803ff7:	29 d0                	sub    %edx,%eax
  803ff9:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  803ffd:	48 98                	cltq   
  803fff:	0f b6 44 02 08       	movzbl 0x8(%rdx,%rax,1),%eax
  804004:	88 01                	mov    %al,(%rcx)
  804006:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80400a:	8b 00                	mov    (%rax),%eax
  80400c:	8d 50 01             	lea    0x1(%rax),%edx
  80400f:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804013:	89 10                	mov    %edx,(%rax)
  804015:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  80401a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80401e:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  804022:	0f 82 60 ff ff ff    	jb     803f88 <devpipe_read+0x40>
  804028:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80402c:	c9                   	leaveq 
  80402d:	c3                   	retq   

000000000080402e <devpipe_write>:
  80402e:	55                   	push   %rbp
  80402f:	48 89 e5             	mov    %rsp,%rbp
  804032:	48 83 ec 40          	sub    $0x40,%rsp
  804036:	48 89 7d d8          	mov    %rdi,-0x28(%rbp)
  80403a:	48 89 75 d0          	mov    %rsi,-0x30(%rbp)
  80403e:	48 89 55 c8          	mov    %rdx,-0x38(%rbp)
  804042:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  804046:	48 89 c7             	mov    %rax,%rdi
  804049:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  804050:	00 00 00 
  804053:	ff d0                	callq  *%rax
  804055:	48 89 45 f0          	mov    %rax,-0x10(%rbp)
  804059:	48 8b 45 d0          	mov    -0x30(%rbp),%rax
  80405d:	48 89 45 e8          	mov    %rax,-0x18(%rbp)
  804061:	48 c7 45 f8 00 00 00 	movq   $0x0,-0x8(%rbp)
  804068:	00 
  804069:	e9 8e 00 00 00       	jmpq   8040fc <devpipe_write+0xce>
  80406e:	eb 31                	jmp    8040a1 <devpipe_write+0x73>
  804070:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  804074:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  804078:	48 89 d6             	mov    %rdx,%rsi
  80407b:	48 89 c7             	mov    %rax,%rdi
  80407e:	48 b8 11 3e 80 00 00 	movabs $0x803e11,%rax
  804085:	00 00 00 
  804088:	ff d0                	callq  *%rax
  80408a:	85 c0                	test   %eax,%eax
  80408c:	74 07                	je     804095 <devpipe_write+0x67>
  80408e:	b8 00 00 00 00       	mov    $0x0,%eax
  804093:	eb 79                	jmp    80410e <devpipe_write+0xe0>
  804095:	48 b8 c8 1e 80 00 00 	movabs $0x801ec8,%rax
  80409c:	00 00 00 
  80409f:	ff d0                	callq  *%rax
  8040a1:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8040a5:	8b 40 04             	mov    0x4(%rax),%eax
  8040a8:	48 63 d0             	movslq %eax,%rdx
  8040ab:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8040af:	8b 00                	mov    (%rax),%eax
  8040b1:	48 98                	cltq   
  8040b3:	48 83 c0 20          	add    $0x20,%rax
  8040b7:	48 39 c2             	cmp    %rax,%rdx
  8040ba:	73 b4                	jae    804070 <devpipe_write+0x42>
  8040bc:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8040c0:	8b 40 04             	mov    0x4(%rax),%eax
  8040c3:	99                   	cltd   
  8040c4:	c1 ea 1b             	shr    $0x1b,%edx
  8040c7:	01 d0                	add    %edx,%eax
  8040c9:	83 e0 1f             	and    $0x1f,%eax
  8040cc:	29 d0                	sub    %edx,%eax
  8040ce:	48 8b 55 f8          	mov    -0x8(%rbp),%rdx
  8040d2:	48 8b 4d e8          	mov    -0x18(%rbp),%rcx
  8040d6:	48 01 ca             	add    %rcx,%rdx
  8040d9:	0f b6 0a             	movzbl (%rdx),%ecx
  8040dc:	48 8b 55 f0          	mov    -0x10(%rbp),%rdx
  8040e0:	48 98                	cltq   
  8040e2:	88 4c 02 08          	mov    %cl,0x8(%rdx,%rax,1)
  8040e6:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8040ea:	8b 40 04             	mov    0x4(%rax),%eax
  8040ed:	8d 50 01             	lea    0x1(%rax),%edx
  8040f0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8040f4:	89 50 04             	mov    %edx,0x4(%rax)
  8040f7:	48 83 45 f8 01       	addq   $0x1,-0x8(%rbp)
  8040fc:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  804100:	48 3b 45 c8          	cmp    -0x38(%rbp),%rax
  804104:	0f 82 64 ff ff ff    	jb     80406e <devpipe_write+0x40>
  80410a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80410e:	c9                   	leaveq 
  80410f:	c3                   	retq   

0000000000804110 <devpipe_stat>:
  804110:	55                   	push   %rbp
  804111:	48 89 e5             	mov    %rsp,%rbp
  804114:	48 83 ec 20          	sub    $0x20,%rsp
  804118:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  80411c:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  804120:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  804124:	48 89 c7             	mov    %rax,%rdi
  804127:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  80412e:	00 00 00 
  804131:	ff d0                	callq  *%rax
  804133:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  804137:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80413b:	48 be ee 4f 80 00 00 	movabs $0x804fee,%rsi
  804142:	00 00 00 
  804145:	48 89 c7             	mov    %rax,%rdi
  804148:	48 b8 d7 15 80 00 00 	movabs $0x8015d7,%rax
  80414f:	00 00 00 
  804152:	ff d0                	callq  *%rax
  804154:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  804158:	8b 50 04             	mov    0x4(%rax),%edx
  80415b:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80415f:	8b 00                	mov    (%rax),%eax
  804161:	29 c2                	sub    %eax,%edx
  804163:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  804167:	89 90 80 00 00 00    	mov    %edx,0x80(%rax)
  80416d:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  804171:	c7 80 84 00 00 00 00 	movl   $0x0,0x84(%rax)
  804178:	00 00 00 
  80417b:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  80417f:	48 b9 e0 70 80 00 00 	movabs $0x8070e0,%rcx
  804186:	00 00 00 
  804189:	48 89 88 88 00 00 00 	mov    %rcx,0x88(%rax)
  804190:	b8 00 00 00 00       	mov    $0x0,%eax
  804195:	c9                   	leaveq 
  804196:	c3                   	retq   

0000000000804197 <devpipe_close>:
  804197:	55                   	push   %rbp
  804198:	48 89 e5             	mov    %rsp,%rbp
  80419b:	48 83 ec 10          	sub    $0x10,%rsp
  80419f:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8041a3:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8041a7:	48 89 c6             	mov    %rax,%rsi
  8041aa:	bf 00 00 00 00       	mov    $0x0,%edi
  8041af:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  8041b6:	00 00 00 
  8041b9:	ff d0                	callq  *%rax
  8041bb:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  8041bf:	48 89 c7             	mov    %rax,%rdi
  8041c2:	48 b8 07 24 80 00 00 	movabs $0x802407,%rax
  8041c9:	00 00 00 
  8041cc:	ff d0                	callq  *%rax
  8041ce:	48 89 c6             	mov    %rax,%rsi
  8041d1:	bf 00 00 00 00       	mov    $0x0,%edi
  8041d6:	48 b8 b1 1f 80 00 00 	movabs $0x801fb1,%rax
  8041dd:	00 00 00 
  8041e0:	ff d0                	callq  *%rax
  8041e2:	c9                   	leaveq 
  8041e3:	c3                   	retq   

00000000008041e4 <wait>:
  8041e4:	55                   	push   %rbp
  8041e5:	48 89 e5             	mov    %rsp,%rbp
  8041e8:	48 83 ec 20          	sub    $0x20,%rsp
  8041ec:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8041ef:	83 7d ec 00          	cmpl   $0x0,-0x14(%rbp)
  8041f3:	75 35                	jne    80422a <wait+0x46>
  8041f5:	48 b9 f5 4f 80 00 00 	movabs $0x804ff5,%rcx
  8041fc:	00 00 00 
  8041ff:	48 ba 00 50 80 00 00 	movabs $0x805000,%rdx
  804206:	00 00 00 
  804209:	be 0a 00 00 00       	mov    $0xa,%esi
  80420e:	48 bf 15 50 80 00 00 	movabs $0x805015,%rdi
  804215:	00 00 00 
  804218:	b8 00 00 00 00       	mov    $0x0,%eax
  80421d:	49 b8 e9 07 80 00 00 	movabs $0x8007e9,%r8
  804224:	00 00 00 
  804227:	41 ff d0             	callq  *%r8
  80422a:	8b 45 ec             	mov    -0x14(%rbp),%eax
  80422d:	25 ff 03 00 00       	and    $0x3ff,%eax
  804232:	48 98                	cltq   
  804234:	48 69 d0 68 01 00 00 	imul   $0x168,%rax,%rdx
  80423b:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  804242:	00 00 00 
  804245:	48 01 d0             	add    %rdx,%rax
  804248:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  80424c:	eb 0c                	jmp    80425a <wait+0x76>
  80424e:	48 b8 c8 1e 80 00 00 	movabs $0x801ec8,%rax
  804255:	00 00 00 
  804258:	ff d0                	callq  *%rax
  80425a:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80425e:	8b 80 c8 00 00 00    	mov    0xc8(%rax),%eax
  804264:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  804267:	75 0e                	jne    804277 <wait+0x93>
  804269:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80426d:	8b 80 d4 00 00 00    	mov    0xd4(%rax),%eax
  804273:	85 c0                	test   %eax,%eax
  804275:	75 d7                	jne    80424e <wait+0x6a>
  804277:	c9                   	leaveq 
  804278:	c3                   	retq   

0000000000804279 <cputchar>:
  804279:	55                   	push   %rbp
  80427a:	48 89 e5             	mov    %rsp,%rbp
  80427d:	48 83 ec 20          	sub    $0x20,%rsp
  804281:	89 7d ec             	mov    %edi,-0x14(%rbp)
  804284:	8b 45 ec             	mov    -0x14(%rbp),%eax
  804287:	88 45 ff             	mov    %al,-0x1(%rbp)
  80428a:	48 8d 45 ff          	lea    -0x1(%rbp),%rax
  80428e:	be 01 00 00 00       	mov    $0x1,%esi
  804293:	48 89 c7             	mov    %rax,%rdi
  804296:	48 b8 be 1d 80 00 00 	movabs $0x801dbe,%rax
  80429d:	00 00 00 
  8042a0:	ff d0                	callq  *%rax
  8042a2:	c9                   	leaveq 
  8042a3:	c3                   	retq   

00000000008042a4 <getchar>:
  8042a4:	55                   	push   %rbp
  8042a5:	48 89 e5             	mov    %rsp,%rbp
  8042a8:	48 83 ec 10          	sub    $0x10,%rsp
  8042ac:	48 8d 45 fb          	lea    -0x5(%rbp),%rax
  8042b0:	ba 01 00 00 00       	mov    $0x1,%edx
  8042b5:	48 89 c6             	mov    %rax,%rsi
  8042b8:	bf 00 00 00 00       	mov    $0x0,%edi
  8042bd:	48 b8 fc 28 80 00 00 	movabs $0x8028fc,%rax
  8042c4:	00 00 00 
  8042c7:	ff d0                	callq  *%rax
  8042c9:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8042cc:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8042d0:	79 05                	jns    8042d7 <getchar+0x33>
  8042d2:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8042d5:	eb 14                	jmp    8042eb <getchar+0x47>
  8042d7:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  8042db:	7f 07                	jg     8042e4 <getchar+0x40>
  8042dd:	b8 f7 ff ff ff       	mov    $0xfffffff7,%eax
  8042e2:	eb 07                	jmp    8042eb <getchar+0x47>
  8042e4:	0f b6 45 fb          	movzbl -0x5(%rbp),%eax
  8042e8:	0f b6 c0             	movzbl %al,%eax
  8042eb:	c9                   	leaveq 
  8042ec:	c3                   	retq   

00000000008042ed <iscons>:
  8042ed:	55                   	push   %rbp
  8042ee:	48 89 e5             	mov    %rsp,%rbp
  8042f1:	48 83 ec 20          	sub    $0x20,%rsp
  8042f5:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8042f8:	48 8d 55 f0          	lea    -0x10(%rbp),%rdx
  8042fc:	8b 45 ec             	mov    -0x14(%rbp),%eax
  8042ff:	48 89 d6             	mov    %rdx,%rsi
  804302:	89 c7                	mov    %eax,%edi
  804304:	48 b8 ca 24 80 00 00 	movabs $0x8024ca,%rax
  80430b:	00 00 00 
  80430e:	ff d0                	callq  *%rax
  804310:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804313:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804317:	79 05                	jns    80431e <iscons+0x31>
  804319:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80431c:	eb 1a                	jmp    804338 <iscons+0x4b>
  80431e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804322:	8b 10                	mov    (%rax),%edx
  804324:	48 b8 20 71 80 00 00 	movabs $0x807120,%rax
  80432b:	00 00 00 
  80432e:	8b 00                	mov    (%rax),%eax
  804330:	39 c2                	cmp    %eax,%edx
  804332:	0f 94 c0             	sete   %al
  804335:	0f b6 c0             	movzbl %al,%eax
  804338:	c9                   	leaveq 
  804339:	c3                   	retq   

000000000080433a <opencons>:
  80433a:	55                   	push   %rbp
  80433b:	48 89 e5             	mov    %rsp,%rbp
  80433e:	48 83 ec 10          	sub    $0x10,%rsp
  804342:	48 8d 45 f0          	lea    -0x10(%rbp),%rax
  804346:	48 89 c7             	mov    %rax,%rdi
  804349:	48 b8 32 24 80 00 00 	movabs $0x802432,%rax
  804350:	00 00 00 
  804353:	ff d0                	callq  *%rax
  804355:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804358:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80435c:	79 05                	jns    804363 <opencons+0x29>
  80435e:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804361:	eb 5b                	jmp    8043be <opencons+0x84>
  804363:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804367:	ba 07 04 00 00       	mov    $0x407,%edx
  80436c:	48 89 c6             	mov    %rax,%rsi
  80436f:	bf 00 00 00 00       	mov    $0x0,%edi
  804374:	48 b8 06 1f 80 00 00 	movabs $0x801f06,%rax
  80437b:	00 00 00 
  80437e:	ff d0                	callq  *%rax
  804380:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804383:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804387:	79 05                	jns    80438e <opencons+0x54>
  804389:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80438c:	eb 30                	jmp    8043be <opencons+0x84>
  80438e:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  804392:	48 ba 20 71 80 00 00 	movabs $0x807120,%rdx
  804399:	00 00 00 
  80439c:	8b 12                	mov    (%rdx),%edx
  80439e:	89 10                	mov    %edx,(%rax)
  8043a0:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8043a4:	c7 40 08 02 00 00 00 	movl   $0x2,0x8(%rax)
  8043ab:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  8043af:	48 89 c7             	mov    %rax,%rdi
  8043b2:	48 b8 e4 23 80 00 00 	movabs $0x8023e4,%rax
  8043b9:	00 00 00 
  8043bc:	ff d0                	callq  *%rax
  8043be:	c9                   	leaveq 
  8043bf:	c3                   	retq   

00000000008043c0 <devcons_read>:
  8043c0:	55                   	push   %rbp
  8043c1:	48 89 e5             	mov    %rsp,%rbp
  8043c4:	48 83 ec 30          	sub    $0x30,%rsp
  8043c8:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  8043cc:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  8043d0:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  8043d4:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8043d9:	75 07                	jne    8043e2 <devcons_read+0x22>
  8043db:	b8 00 00 00 00       	mov    $0x0,%eax
  8043e0:	eb 4b                	jmp    80442d <devcons_read+0x6d>
  8043e2:	eb 0c                	jmp    8043f0 <devcons_read+0x30>
  8043e4:	48 b8 c8 1e 80 00 00 	movabs $0x801ec8,%rax
  8043eb:	00 00 00 
  8043ee:	ff d0                	callq  *%rax
  8043f0:	48 b8 08 1e 80 00 00 	movabs $0x801e08,%rax
  8043f7:	00 00 00 
  8043fa:	ff d0                	callq  *%rax
  8043fc:	89 45 fc             	mov    %eax,-0x4(%rbp)
  8043ff:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804403:	74 df                	je     8043e4 <devcons_read+0x24>
  804405:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  804409:	79 05                	jns    804410 <devcons_read+0x50>
  80440b:	8b 45 fc             	mov    -0x4(%rbp),%eax
  80440e:	eb 1d                	jmp    80442d <devcons_read+0x6d>
  804410:	83 7d fc 04          	cmpl   $0x4,-0x4(%rbp)
  804414:	75 07                	jne    80441d <devcons_read+0x5d>
  804416:	b8 00 00 00 00       	mov    $0x0,%eax
  80441b:	eb 10                	jmp    80442d <devcons_read+0x6d>
  80441d:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804420:	89 c2                	mov    %eax,%edx
  804422:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  804426:	88 10                	mov    %dl,(%rax)
  804428:	b8 01 00 00 00       	mov    $0x1,%eax
  80442d:	c9                   	leaveq 
  80442e:	c3                   	retq   

000000000080442f <devcons_write>:
  80442f:	55                   	push   %rbp
  804430:	48 89 e5             	mov    %rsp,%rbp
  804433:	48 81 ec b0 00 00 00 	sub    $0xb0,%rsp
  80443a:	48 89 bd 68 ff ff ff 	mov    %rdi,-0x98(%rbp)
  804441:	48 89 b5 60 ff ff ff 	mov    %rsi,-0xa0(%rbp)
  804448:	48 89 95 58 ff ff ff 	mov    %rdx,-0xa8(%rbp)
  80444f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  804456:	eb 76                	jmp    8044ce <devcons_write+0x9f>
  804458:	48 8b 85 58 ff ff ff 	mov    -0xa8(%rbp),%rax
  80445f:	89 c2                	mov    %eax,%edx
  804461:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804464:	29 c2                	sub    %eax,%edx
  804466:	89 d0                	mov    %edx,%eax
  804468:	89 45 f8             	mov    %eax,-0x8(%rbp)
  80446b:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80446e:	83 f8 7f             	cmp    $0x7f,%eax
  804471:	76 07                	jbe    80447a <devcons_write+0x4b>
  804473:	c7 45 f8 7f 00 00 00 	movl   $0x7f,-0x8(%rbp)
  80447a:	8b 45 f8             	mov    -0x8(%rbp),%eax
  80447d:	48 63 d0             	movslq %eax,%rdx
  804480:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804483:	48 63 c8             	movslq %eax,%rcx
  804486:	48 8b 85 60 ff ff ff 	mov    -0xa0(%rbp),%rax
  80448d:	48 01 c1             	add    %rax,%rcx
  804490:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  804497:	48 89 ce             	mov    %rcx,%rsi
  80449a:	48 89 c7             	mov    %rax,%rdi
  80449d:	48 b8 fb 18 80 00 00 	movabs $0x8018fb,%rax
  8044a4:	00 00 00 
  8044a7:	ff d0                	callq  *%rax
  8044a9:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8044ac:	48 63 d0             	movslq %eax,%rdx
  8044af:	48 8d 85 70 ff ff ff 	lea    -0x90(%rbp),%rax
  8044b6:	48 89 d6             	mov    %rdx,%rsi
  8044b9:	48 89 c7             	mov    %rax,%rdi
  8044bc:	48 b8 be 1d 80 00 00 	movabs $0x801dbe,%rax
  8044c3:	00 00 00 
  8044c6:	ff d0                	callq  *%rax
  8044c8:	8b 45 f8             	mov    -0x8(%rbp),%eax
  8044cb:	01 45 fc             	add    %eax,-0x4(%rbp)
  8044ce:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8044d1:	48 98                	cltq   
  8044d3:	48 3b 85 58 ff ff ff 	cmp    -0xa8(%rbp),%rax
  8044da:	0f 82 78 ff ff ff    	jb     804458 <devcons_write+0x29>
  8044e0:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8044e3:	c9                   	leaveq 
  8044e4:	c3                   	retq   

00000000008044e5 <devcons_close>:
  8044e5:	55                   	push   %rbp
  8044e6:	48 89 e5             	mov    %rsp,%rbp
  8044e9:	48 83 ec 08          	sub    $0x8,%rsp
  8044ed:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  8044f1:	b8 00 00 00 00       	mov    $0x0,%eax
  8044f6:	c9                   	leaveq 
  8044f7:	c3                   	retq   

00000000008044f8 <devcons_stat>:
  8044f8:	55                   	push   %rbp
  8044f9:	48 89 e5             	mov    %rsp,%rbp
  8044fc:	48 83 ec 10          	sub    $0x10,%rsp
  804500:	48 89 7d f8          	mov    %rdi,-0x8(%rbp)
  804504:	48 89 75 f0          	mov    %rsi,-0x10(%rbp)
  804508:	48 8b 45 f0          	mov    -0x10(%rbp),%rax
  80450c:	48 be 28 50 80 00 00 	movabs $0x805028,%rsi
  804513:	00 00 00 
  804516:	48 89 c7             	mov    %rax,%rdi
  804519:	48 b8 d7 15 80 00 00 	movabs $0x8015d7,%rax
  804520:	00 00 00 
  804523:	ff d0                	callq  *%rax
  804525:	b8 00 00 00 00       	mov    $0x0,%eax
  80452a:	c9                   	leaveq 
  80452b:	c3                   	retq   

000000000080452c <ipc_recv>:
  80452c:	55                   	push   %rbp
  80452d:	48 89 e5             	mov    %rsp,%rbp
  804530:	48 83 ec 30          	sub    $0x30,%rsp
  804534:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  804538:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
  80453c:	48 89 55 d8          	mov    %rdx,-0x28(%rbp)
  804540:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  804545:	75 0e                	jne    804555 <ipc_recv+0x29>
  804547:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  80454e:	00 00 00 
  804551:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  804555:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
  804559:	48 89 c7             	mov    %rax,%rdi
  80455c:	48 b8 2f 21 80 00 00 	movabs $0x80212f,%rax
  804563:	00 00 00 
  804566:	ff d0                	callq  *%rax
  804568:	89 45 fc             	mov    %eax,-0x4(%rbp)
  80456b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80456f:	79 27                	jns    804598 <ipc_recv+0x6c>
  804571:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  804576:	74 0a                	je     804582 <ipc_recv+0x56>
  804578:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80457c:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  804582:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  804587:	74 0a                	je     804593 <ipc_recv+0x67>
  804589:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  80458d:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
  804593:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804596:	eb 53                	jmp    8045eb <ipc_recv+0xbf>
  804598:	48 83 7d e8 00       	cmpq   $0x0,-0x18(%rbp)
  80459d:	74 19                	je     8045b8 <ipc_recv+0x8c>
  80459f:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  8045a6:	00 00 00 
  8045a9:	48 8b 00             	mov    (%rax),%rax
  8045ac:	8b 90 0c 01 00 00    	mov    0x10c(%rax),%edx
  8045b2:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  8045b6:	89 10                	mov    %edx,(%rax)
  8045b8:	48 83 7d d8 00       	cmpq   $0x0,-0x28(%rbp)
  8045bd:	74 19                	je     8045d8 <ipc_recv+0xac>
  8045bf:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  8045c6:	00 00 00 
  8045c9:	48 8b 00             	mov    (%rax),%rax
  8045cc:	8b 90 10 01 00 00    	mov    0x110(%rax),%edx
  8045d2:	48 8b 45 d8          	mov    -0x28(%rbp),%rax
  8045d6:	89 10                	mov    %edx,(%rax)
  8045d8:	48 b8 08 80 80 00 00 	movabs $0x808008,%rax
  8045df:	00 00 00 
  8045e2:	48 8b 00             	mov    (%rax),%rax
  8045e5:	8b 80 08 01 00 00    	mov    0x108(%rax),%eax
  8045eb:	c9                   	leaveq 
  8045ec:	c3                   	retq   

00000000008045ed <ipc_send>:
  8045ed:	55                   	push   %rbp
  8045ee:	48 89 e5             	mov    %rsp,%rbp
  8045f1:	48 83 ec 30          	sub    $0x30,%rsp
  8045f5:	89 7d ec             	mov    %edi,-0x14(%rbp)
  8045f8:	89 75 e8             	mov    %esi,-0x18(%rbp)
  8045fb:	48 89 55 e0          	mov    %rdx,-0x20(%rbp)
  8045ff:	89 4d dc             	mov    %ecx,-0x24(%rbp)
  804602:	48 83 7d e0 00       	cmpq   $0x0,-0x20(%rbp)
  804607:	75 10                	jne    804619 <ipc_send+0x2c>
  804609:	48 b8 00 00 80 00 80 	movabs $0x8000800000,%rax
  804610:	00 00 00 
  804613:	48 89 45 e0          	mov    %rax,-0x20(%rbp)
  804617:	eb 0e                	jmp    804627 <ipc_send+0x3a>
  804619:	eb 0c                	jmp    804627 <ipc_send+0x3a>
  80461b:	48 b8 c8 1e 80 00 00 	movabs $0x801ec8,%rax
  804622:	00 00 00 
  804625:	ff d0                	callq  *%rax
  804627:	8b 75 e8             	mov    -0x18(%rbp),%esi
  80462a:	8b 4d dc             	mov    -0x24(%rbp),%ecx
  80462d:	48 8b 55 e0          	mov    -0x20(%rbp),%rdx
  804631:	8b 45 ec             	mov    -0x14(%rbp),%eax
  804634:	89 c7                	mov    %eax,%edi
  804636:	48 b8 da 20 80 00 00 	movabs $0x8020da,%rax
  80463d:	00 00 00 
  804640:	ff d0                	callq  *%rax
  804642:	89 45 fc             	mov    %eax,-0x4(%rbp)
  804645:	83 7d fc f8          	cmpl   $0xfffffff8,-0x4(%rbp)
  804649:	74 d0                	je     80461b <ipc_send+0x2e>
  80464b:	83 7d fc 00          	cmpl   $0x0,-0x4(%rbp)
  80464f:	79 30                	jns    804681 <ipc_send+0x94>
  804651:	8b 45 fc             	mov    -0x4(%rbp),%eax
  804654:	89 c1                	mov    %eax,%ecx
  804656:	48 ba 2f 50 80 00 00 	movabs $0x80502f,%rdx
  80465d:	00 00 00 
  804660:	be 44 00 00 00       	mov    $0x44,%esi
  804665:	48 bf 45 50 80 00 00 	movabs $0x805045,%rdi
  80466c:	00 00 00 
  80466f:	b8 00 00 00 00       	mov    $0x0,%eax
  804674:	49 b8 e9 07 80 00 00 	movabs $0x8007e9,%r8
  80467b:	00 00 00 
  80467e:	41 ff d0             	callq  *%r8
  804681:	c9                   	leaveq 
  804682:	c3                   	retq   

0000000000804683 <ipc_find_env>:
  804683:	55                   	push   %rbp
  804684:	48 89 e5             	mov    %rsp,%rbp
  804687:	48 83 ec 14          	sub    $0x14,%rsp
  80468b:	89 7d ec             	mov    %edi,-0x14(%rbp)
  80468e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%rbp)
  804695:	eb 4e                	jmp    8046e5 <ipc_find_env+0x62>
  804697:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  80469e:	00 00 00 
  8046a1:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8046a4:	48 98                	cltq   
  8046a6:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  8046ad:	48 01 d0             	add    %rdx,%rax
  8046b0:	48 05 d0 00 00 00    	add    $0xd0,%rax
  8046b6:	8b 00                	mov    (%rax),%eax
  8046b8:	3b 45 ec             	cmp    -0x14(%rbp),%eax
  8046bb:	75 24                	jne    8046e1 <ipc_find_env+0x5e>
  8046bd:	48 ba 00 00 80 00 80 	movabs $0x8000800000,%rdx
  8046c4:	00 00 00 
  8046c7:	8b 45 fc             	mov    -0x4(%rbp),%eax
  8046ca:	48 98                	cltq   
  8046cc:	48 69 c0 68 01 00 00 	imul   $0x168,%rax,%rax
  8046d3:	48 01 d0             	add    %rdx,%rax
  8046d6:	48 05 c0 00 00 00    	add    $0xc0,%rax
  8046dc:	8b 40 08             	mov    0x8(%rax),%eax
  8046df:	eb 12                	jmp    8046f3 <ipc_find_env+0x70>
  8046e1:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
  8046e5:	81 7d fc ff 03 00 00 	cmpl   $0x3ff,-0x4(%rbp)
  8046ec:	7e a9                	jle    804697 <ipc_find_env+0x14>
  8046ee:	b8 00 00 00 00       	mov    $0x0,%eax
  8046f3:	c9                   	leaveq 
  8046f4:	c3                   	retq   

00000000008046f5 <pageref>:
  8046f5:	55                   	push   %rbp
  8046f6:	48 89 e5             	mov    %rsp,%rbp
  8046f9:	48 83 ec 18          	sub    $0x18,%rsp
  8046fd:	48 89 7d e8          	mov    %rdi,-0x18(%rbp)
  804701:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  804705:	48 c1 e8 15          	shr    $0x15,%rax
  804709:	48 89 c2             	mov    %rax,%rdx
  80470c:	48 b8 00 00 00 80 00 	movabs $0x10080000000,%rax
  804713:	01 00 00 
  804716:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  80471a:	83 e0 01             	and    $0x1,%eax
  80471d:	48 85 c0             	test   %rax,%rax
  804720:	75 07                	jne    804729 <pageref+0x34>
  804722:	b8 00 00 00 00       	mov    $0x0,%eax
  804727:	eb 53                	jmp    80477c <pageref+0x87>
  804729:	48 8b 45 e8          	mov    -0x18(%rbp),%rax
  80472d:	48 c1 e8 0c          	shr    $0xc,%rax
  804731:	48 89 c2             	mov    %rax,%rdx
  804734:	48 b8 00 00 00 00 00 	movabs $0x10000000000,%rax
  80473b:	01 00 00 
  80473e:	48 8b 04 d0          	mov    (%rax,%rdx,8),%rax
  804742:	48 89 45 f8          	mov    %rax,-0x8(%rbp)
  804746:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80474a:	83 e0 01             	and    $0x1,%eax
  80474d:	48 85 c0             	test   %rax,%rax
  804750:	75 07                	jne    804759 <pageref+0x64>
  804752:	b8 00 00 00 00       	mov    $0x0,%eax
  804757:	eb 23                	jmp    80477c <pageref+0x87>
  804759:	48 8b 45 f8          	mov    -0x8(%rbp),%rax
  80475d:	48 c1 e8 0c          	shr    $0xc,%rax
  804761:	48 89 c2             	mov    %rax,%rdx
  804764:	48 b8 00 00 a0 00 80 	movabs $0x8000a00000,%rax
  80476b:	00 00 00 
  80476e:	48 c1 e2 04          	shl    $0x4,%rdx
  804772:	48 01 d0             	add    %rdx,%rax
  804775:	0f b7 40 08          	movzwl 0x8(%rax),%eax
  804779:	0f b7 c0             	movzwl %ax,%eax
  80477c:	c9                   	leaveq 
  80477d:	c3                   	retq   
