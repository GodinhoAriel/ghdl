/*  GRT stack implementation for x86.
    Copyright (C) 2002 - 2014 Tristan Gingold.

    GHDL is free software; you can redistribute it and/or modify it under
    the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2, or (at your option) any later
    version.

    GHDL is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with GCC; see the file COPYING.  If not, write to the Free
    Software Foundation, 59 Temple Place - Suite 330, Boston, MA
    02111-1307, USA.

    As a special exception, if other files instantiate generics from this
    unit, or you link this unit with other files to produce an executable,
    this unit does not by itself cause the resulting executable to be
    covered by the GNU General Public License. This exception does not
    however invalidate any other reasons why the executable file might be
    covered by the GNU Public License.
*/
	.file		"i386.S"
	.version	"01.01"

	.text

#ifdef __ELF__
#define ENTRY(func) .align 4; .globl func; .type func,@function; func:
#define END(func) .size func, . - func
#define NAME(name) name
#elif __APPLE__
#define ENTRY(func) .align 4; .globl _##func; _##func:
#define END(func)
#define NAME(name) _##name
#else
#define ENTRY(func) .align 4; func:
#define END(func)
#define NAME(name) name
#endif

	/* Function called to loop on the process.  */
ENTRY(grt_stack_loop)
	call	*4(%esp)
	jmp	NAME(grt_stack_loop)
END(grt_stack_loop)

	/* function Stack_Create (Func : Address; Arg : Address)
 	                          return Stack_Type;
	*/
ENTRY(grt_stack_create)
	/* Standard prologue.  */
	pushl	%ebp
	movl	%esp,%ebp
	/* Keep aligned (call + pushl + 8 = 16 bytes).  */
	subl	$8,%esp

	/* Allocate the stack, and exit in case of failure  */
	call	NAME(grt_stack_allocate)
	testl	%eax,%eax
	je	.Ldone

	/* Note: %EAX contains the address of the stack_context.  This is
	   also the top of the stack.  */

	/* Prepare stack.  */
	/* The function to be executed.  */
	movl	8(%ebp), %ecx
	movl	%ecx, -4(%eax)
	/* The argument.  */
	movl	12(%ebp), %ecx
	movl	%ecx, -8(%eax)
	/* The return function.  */
#if __APPLE__
	call	___x86.get_pc_thunk.cx
L1$pb:
	movl	L_grt_stack_loop$non_lazy_ptr-L1$pb(%ecx), %ecx
	movl	%ecx,-12(%eax)
#else
	movl	$NAME(grt_stack_loop), -12(%eax)
#endif
	/* The context.  */
	movl	%ebx, -16(%eax)
	movl	%esi, -20(%eax)
	movl	%edi, -24(%eax)
	movl	%ebp, -28(%eax)

	/* Save the new stack pointer to the stack context.  */
	leal	-28(%eax), %ecx
	movl	%ecx, (%eax)

.Ldone:
	leave
	ret
END(grt_stack_create)


	/* Arguments:	TO, FROM
	   Both are pointers to a stack_context.  */
ENTRY(grt_stack_switch)
	/* TO -> ECX.  */
	movl	4(%esp), %ecx
	/* FROM -> EDX.  */
	movl	8(%esp), %edx
	/* Save call-used registers.  */
	pushl	%ebx
	pushl	%esi
	pushl	%edi
	pushl	%ebp
	/* Save the current stack.  */
	movl	%esp, (%edx)
	/* Stack switch.  */
	movl	(%ecx), %esp
	/* Restore call-used registers.  */
	popl	%ebp
	popl	%edi
	popl	%esi
	popl	%ebx
	/* Run.  */
	ret
END(grt_stack_switch)


#if __APPLE__
	.section __TEXT,__textcoal_nt,coalesced,pure_instructions
	.weak_definition ___x86.get_pc_thunk.cx
	.private_extern	___x86.get_pc_thunk.cx
___x86.get_pc_thunk.cx:
	movl	(%esp), %ecx
	ret

	.section __IMPORT,__pointers,non_lazy_symbol_pointers
L_grt_stack_loop$non_lazy_ptr:
	.indirect_symbol _grt_stack_loop
	.long	0
#endif

	.ident	"Written by T.Gingold"
