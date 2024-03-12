# 数字电路课程设计报告

## **一. 项目背景**

本课程设计的目的是利用基本的FPGA开发工具，在FPGA上实现一个可以运行基础指令集（包含ADD、SUB、MOV、AND、OR、LDR、STR、B/BL）和拓展指令集的MCU，并利用设计的MCU完成以下两个设计中的一个

- 设计一：卷积

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled.png)

- 设计二：LDPC

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled%201.png)

在综合考虑后，我们选择了设计2，并将任务划分成两个基本模块：MCU的设计和搜索算法的汇编实现。

## **二. 设计思路**

由于团队缺少开发FPGA的基本经验，我们决定先完成能够执行基本指令集的MCU。在Digital Design and Computer Architecture，ARM® Edition中已经提供了基本数据通路各个部件的实现，我们参考其中的代码，完成了MCU模块的设计。

在完成MCU后，我们对LDPC进行了细致的分析，设计并撰写了DFS/BFS/状压dp的C语言及汇编语言代码。为更加方便的实现C语言到机器码的过程，我们结合编译器和Keil 4 开发工具实现了一个Python工具。同时，为提高效率，减少MCU开发成本，我们决定在该Python工具的基础上进行一些改进，在将C语言转为汇编代码的同时，对相关复杂指令进行修改，达到用基础指令实现复杂汇编的目的。基于该Python工具，我们可以将有关C语言代码转为MCU可以运行的汇编代码，辅助完成汇编设计。Update:由于更新时代久远，原python代码找不到了:(

完成MCU与汇编代码后，我们在MCU上增加了RAM与ROM模块，将数据与指令分别存入其中，并利用 ILA (Integrated Logic Analyzer) 测试工具进行上板测试。

## 三.算法设计与实现

我们先后设计了DFS/BFS/状态压缩动态规划3种算法来解决这个问题，经过综合分析比较，最终选择了BFS(广度优先搜索）方案。

### 问题回顾

给定一张二分无向图，上下各有 $n,m$ 个点。分别求出图中长度为 $4,6,8$  的环的数量。

$1\le n,m \le 8$

### **算法1：DFS**

深度优先搜索是解决该问题的常规思路。算法步骤如下：

- 将下方结点编号为  $n+1,n+2,...,n+m$ ，构造 $n+m$ 个点的邻接矩阵
- 分别以 $1,2,3,...,n$  号为起点进行DFS
- DFS的过程中，记录**已走过的步数**和**在栈中的结点**
    - 前者直接作为函数参数传递即可,初始令`step = 1`。
    - 后者较为简单的实现是：维护一个全局数组`vis`, 结点 v 入栈时标记 `vis[v] = 1`,出栈时标记`vis[v] = 0`。
        
        ```cpp
        void dfs(int u, int step) {
        	...
        	//当前结点为u
        	for (int v = 1; v <= n + m; v++) {
        	    if (G[u][v] && vis[v] == 0) {
        	        vis[v] = 1;
        	        dfs(v, step + 1);
        	        vis[v] = 0;
        	    }
        	}
        	...
        }
        ```
        
    - 可以进行如下优化：由于总点数较少，可以将全局数组`vis`改为一个全局变量，利用二进制状态压缩代替数组赋值:
        
        ```cpp
        //当前结点为u
        for (int v = 1; v <= n + m; v++) {
            if (G[u][v] && (vis & (1 << u) == 0) {  //如果vis[u] = 0
                vis = vis + (1 << u);               //vis[u] = 1;
                dfs(v, step + 1);
                vis = vis - (1 << u);               //vis[u] = 0;
            }
            ...
        }
        ```
        
- 如果当前结点连向已在栈中的结点，根据已走过的步数对相应答案计数。
    
    ```cpp
    ...
    if (vis[v]) {
        if (step == 4) ans4++;
        if (step == 6) ans6++;
        if (step == 8) ans8++;
    }
    ```
    
- 最后统计答案
    - 由于二分图的特性，我们从上边的点开始搜索，则环中有一半的点作为起点被统计到，且每个起点从两个方向走回起点，各被统计了 2 次, 因此长度为 $n$ 的环恰好被统计 $n$ 次， `ans4/ans6/ans8`分别除以`4/6/8`即为最终答案。
    - 考虑到硬件添加除法指令的开销较大，需改写除法。除以4、8可以通过右移实现，而除以6可以改写为循环+减法。
        
        ```cpp
        ans4 = ans4 >> 2;
        
        tmp = ans6;
        ans6 = 0;
        while (tmp != 0) {
            tmp -= 6;
            ans6++;
        }
        
        ans8 = ans8 >> 3;
        ```
        

### **算法2：BFS**

此外，BFS也是该问题的解决思路之一。除了搜索顺序改变以外，其他部分与DFS类似。

BFS使用队列实现，程序顺序执行，没有递归调用，方便汇编实现与调试。

在广度优先搜索中，每个状态可以由`now` (当前结点), `step` (当前步数),  `vis`(当前访问过的点)三个变量来表示。为了节省存储空间，此处`vis`使用算法1中提到的状态压缩优化，将路径中访问过的结点以二进制形式记录在一个整形变量中。

BFS算法的核心代码如下：

```cpp

//分别以1,2,3,...n号点为起点进行BFS
for (i = 1; i <= n; i++) {
    head = 0; tail = 1;
    qnow[head] = i; qstep[head] = 1; qvis[head] = 1 << i;

    while (head < tail) {
        int now = qnow[head], step = qstep[head], vis = qvis[head];
        if (step > 8) {              //步数大于8，停止搜索
            head++;
            continue;
        }
        if (now <= n) {              //如果当前是上方点，只向下方搜索，反之亦然
            l = n + 1; r = n + m;
        } else {
            l = 1; r = n;
        }
        for (int nxt = l; nxt <= r; nxt++) {
            if (nxt == i && G[now][nxt] == 1) {
                if (step == 4) ans4++;
                if (step == 6) ans6++;
                if (step == 8) ans8++;
                continue;
            }
            if ((vis & (1 << nxt)) == 0 && G[now][nxt] == 1) {  //如果没有访问过nxt
                qnow[tail] = nxt;
                qstep[tail] = step + 1;
                qvis[tail] = vis | (1 << nxt);     //vis二进制第nxt位置为1，标记nxt已访问
                tail++;
            }
        }
        head++;
    }
}
```

### **算法3：状压dp**

上述DFS和BFS算法为了实现环计数，只限定了不访问路径中已经过的点，单次搜索中每个结点都可能被多次重复访问。考虑满二分图的极限情况，算法的复杂度将达到阶乘级别。

为此，我们也考虑了算法竞赛中常见的一种针对小规模数据的指数算法——状态压缩动态规划。

我们记`dp[j][i]` 表示某路径所经过的结点集合为`i` （以二进制表示集合），路径终点为`j` 的路径条数。

初始化所有结点作为起点：

```cpp
for(i = 1; i <= n; i++) dp[i][1 << (i - 1)] = 1;
```

枚举下一个结点`k` 。我们规定状态`i` 中二进制最低位`lowbit(i) = i & -i` 为路径起点，则当存在`k = i` 的边时，就找到了`dp[j][i]`条环路，且该环路的长度为状态`i`中的结点数（即二进制中’1‘的个数）。

由于一个环被规定以编号最小的点为起点，从两个方向回到原点，任何长度的环都被统计了2次，最终将答案除以2（右移1）即可。

该算法具有明确的时间复杂度 $O(n^2\cdot 2^n)$ , $n$   为总点数。核心代码如下：

```cpp
.
    n = n + m;
    for(i = 1; i <= n; i++)
        dp[i][1 << (i - 1)] = 1;
    int tot = 0;
    for(i = 0; i < (1 << n); i++) {
        for(j = 1; j <= n; j++) {
            for(k = 1; k <= n; k++) {
                tot++;
                if(!G[k][j] || (i & -i) > (1 << (k - 1))) continue;
                if((1 << (k - 1) & i) && 1 << (k - 1) == (i & -i)) {
                    cnt = 0;
                    tmp = i;
                    while (tmp != 0) {           //统计当前状态i 二进制中1的个数
                        tmp = tmp - (tmp & -tmp);
                        cnt++;
                    }
                    if (cnt == 4) ans4 = ans4 + dp[j][i];
                    if (cnt == 6) ans6 = ans6 + dp[j][i];
                    if (cnt == 8) ans8 = ans8 + dp[j][i];
                } else {
                    dp[k][i ^ 1 << (k - 1)] += dp[j][i];
                }
            }
        }
    }
    ans4 = ans4 >> 1;
    ans6 = ans6 >> 1;
    ans8 = ans8 >> 1;
```

### 三种算法的比较与选择

理论上讲，状压dp在最坏情况（稠密图）下具有最优的时间复杂度。然而，本题目的数据生成器对图的稠密度进行了限制，实测效率并不如两种搜索算法。且状态存储需要大量空间(至少$2^{16}$ 个整型变量)，超出了FPGA的资源限制。因此排除了状压dp的方案。

我们利用LDPC_code.m生成了一组较大的数据($n=7,m=8)$进行测试，DFS和BFS算法都得到了正确结果。DFS进行了58117次函数调用（入栈），BFS进行了33779次入队，效率更佳。加之BFS无需递归调用，易于实现和调试，我们选择了BFS作为最终的方案。

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled.jpeg)

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled%201.jpeg)

### 汇编程序设计

我们使用ARM GCC编译器，开启`-march=armv4` 编译选项，由C语言代码生成初步的armv4汇编程序。并编写python脚本，对汇编程序进行改写，以适应我们的MCU。包括：

- 增加从coe初始化的存储器中读取数据的指令
- 优化跳转标记
- 将未实现的指令改写为已实现的指令
- 将部分指令拆分为多条指令
    - 例如，在ARM数据处理指令中，超过8位的立即数在编译时会自动采用移位寻址表示，需要修改MCU控制器和数据通路才能正确执行。
    - 我们将这样的指令拆分为 一条移位运算指令（我们的MCU拓展了移位运算指令）+ 一条寄存器寻址的数据处理指令 两条指令。

最后，我们在程序的末尾添加了三条LDR指令。以便观察`ans4/ans6/ans8` 的最终结果。

```nasm
LDR R3,[sp, #-8]
LDR R3,[sp, #-12]
LDR R3,[sp, #-16]
```

我们将`ans4/ans6/ans8` 存放在了内存`[sp,#-8/-12/-16]`的位置，因此执行最后三条指令时，可以通过keil仿真时观察R3的值来验证结果的正确性，也可以将MCU中的s_Read_Data信号在仿真和上板时进行监视来观察结果。

### 调试与机器码生成

我们使用keil μvision4的ARM7TDMI环境来仿真ARM程序的执行过程，并加入如下编译选项以生成机器码

```nasm
...\fromelf.exe --text -a -c --output=armtest_asm.txt ".\armtest.axf"
```

我们充分利用了keil的debug功能，观察程序执行过程中寄存器和内存中值的变化，进行程序调试

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled%202.png)

## 四.ALU与MCU设计

### 1.  ALU设计

在一个算术逻辑单元（ALU）内组合了多种算法和逻辑的操作。ALU可以执行加法、减法、AND、OR操作。当两个源操作数A、B输入进ALU后，在ALU内同时进行加减与或计算，再通过控制信号与多路选通器进行输出结果的选择，最后计算N、E、C、V四个标志位，并输出标志位。

要求做一个门级ALU，输入两个源操作数A、B，输出结果Result与标志位。

### Result

![1.png](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/1.png)

数据通路如上图。

- ALUControl信号控制计算结果的选择。‘00’表示‘A+B‘，‘01’表示‘A-B’，‘10’表示‘A&B’，‘11’表示‘A|B’。
- 加法用行波进位加法器实现。

$$
Cout = Cin+A[i]+B[i]
$$

输入上一个全加器的进位Cin、对应的源操作数位A[i]、B[i]，输出计算结果Cout、进位Cin。

- 减法与加法类似，只是将第二个源操作数(B)变为它的相反数(-B)，即取反后加一。
- 按位与与按位或都是一位一位地进行计算后将结果拼在一起。

### 标志位

标志位为四位，分别是N（负数位），Z（零位），C（进位位），V（溢出位）。

- N位：

$$
N=Result[31]
$$

- Z位：

$$
Z=Result'
$$

- C位：

$$
C=ALUControl[1]'*Cout
$$

- V位：

$$
V=(ALUControl[1]')*(A[31]\land   Sum[31])*(A[31] \land B[31] \land ALUControl[0])'
$$

### 多路选通

因为ALU是门级描述，不能使用if/else语句，所以多路选通实现如下：

$$
Result = ResultADD*ALUControl[0]'*ALUControl[1]'+ResultSUB*ALUControl[0]*ALUControl[1]'+ResultAND*ALUControl[0]'*ALUControl[1]+ResultOR*ALUControl[0]*ALUControl[1]
$$

### 2. MCU设计

MCU分为CPU部分与存储部分。CPU部分分为控制通路与数据通路。控制通路负责指令译码与控制信号产生；数据通路负责计算与寄存器读取与存储。存储部分分为指令存储与数据存储。指令存在ROM中；数据存在RAM中。

### CPU部分

CPU部分实现指令执行的大部分，包括读指令、译码、产生控制信号、计算、写寄存器等操作。

输入时钟CLK、复位信号RESET、在寄存器中读取的数，输出PC值，写入的地址，写入的数据。

### 控制通路

控制通路读入时钟CLK、复位信号RESET、当前正在执行的32位指令、上一拍ALU执行产生的标志位，输出控制信号与条件码。

译码包括ALU译码、主要译码、PC地址选择。

- ALU译码部分根据控制信号i_ALU_Operation控制ALU的是否进行计算工作，若ALU需要进行计算工作，再通过指令的第20到25位识别指令是进行什么运算。我们的MCU实现了六种运算操作：ADD、SUB、AND、ORR、SHF（移位操作）、CMP（比较操作）。再通过六种操作生成相应的控制信号。生成的控制信号有：三位的ALU_Control，在数据通路中控制ALU执行的运算类型；一位o_No_Write信号，控制是否需要将结果写回寄存器。

```verilog
module	ARM_SyngleCycle_ALU_Decoder  //ALU译码
	(input logic[4:0]	i_Funct,
	input logic			i_ALU_Operation,
	output logic[2:0]  o_ALU_Control,
	output logic[1:0]	o_Flag_Write,
	output logic		o_No_Write);
```

- 主要译码部分根据指令的Op与Funct部分识别DATA_PROCESSING、MEM_CONTROL、BRANCH中的哪一种指令，再根据不同的指令类型，生成不同的控制信号。如o_Branch控制是否需要跳转，即下一拍PC的值是多少；o_Reg_Write控制是否需要回写寄存器；o_Mem_Write控制是否需要回写存储器；o_ALU_Src控制ALU操作数来源，控制操作数是来源于立即数还是来源于寄存器；o_Imm_Src控制立即数扩展的方式；o_ALU_Operation控制是否需要存储ALU的计算结果。

```verilog
module	ARM_SyngleCycle_Main_Decoder  //主要译码
	(input logic[1:0]	i_Op, i_Funct,
	
	output logic[1:0]	o_Reg_Src, o_Imm_Src,
	output logic		o_ALU_Src,
	output logic		o_Reg_Write, o_Mem_Write,
	output logic		o_Mem_ToReg,
	
	output logic		o_ALU_Operation,
	output logic		o_Branch);
```

- PC地址选择将决定下一拍的PC地址。输入源操作数寄存器地址，输入i_Branch, i_Reg_Write信号判断是否需要跳转，输出o_PC_Src信号，判断是否需要跳转。

```verilog
module	ARM_SyngleCycle_PC_Logic
	(input logic[3:0]	i_Rd,
	input logic			i_Branch, i_Reg_Write,
	output logic		o_PC_Src);
```

条件码的生成部分输入时钟CLK、复位信号RESET、状态码cond、ALU标志位，是否需要修改ALU标志位的信号i_Flag_Write、是否需要回写寄存器的信号与是否需要回写存储器的信号i_Reg_Write,与i_Mem_Write、是否需要将ALU结果写入寄存器的信号i_No_Write；输出下一拍PC的值的控制信号o_PC_Src、o_Reg_Write, o_Mem_Write信号等。

- 条件码的生成与ALU的计算结果标志位有关。如Z位为0，对应的条件码是EQ；Z位不为0，对应的条件码为NE等。
- 根据生成的条件码，决定控制信号。

```verilog
	module	ARM_SyngleCycle_ConditionalLogic 
	(input logic		i_CLK, i_RESET,
	
	input logic[3:0]	i_Cond,
	input logic[3:0]	i_ALU_Flags,
	
	input logic[1:0]	i_Flag_Write,
	input logic			i_PC_Src,
	input logic			i_Reg_Write, i_Mem_Write,
	input logic			i_No_Write,
	
	output logic		o_PC_Src,
	output logic		o_Reg_Write, o_Mem_Write);

module	ARM_SyngleCycle_ConditionCheck
	(input logic[3:0]	i_Cond,
	input logic[1:0]	i_Flags_NZ,
	input logic[1:0]	i_Flags_CV,
	
	output logic		o_Cond_Executed);
```

### 数据通路

数据通路读入控制通路产生的控制信号、32位指令、ALU操作码，输出ALU状态码、ALU计算结果、PC的值、写入存储器中的值。

- 在数据通路中首先读入寄存器中的值，如果有立即数，对立即数进行位扩展，对立即数进行移位操作，再根据ALU的控制信号进行计算，再根据控制信号判断是否需要写入存储器或回写寄存器。
- 在数据通路中还实现了多路选通器，根据控制信号进行两个信号的选通。
- 在此次设计的MCU的ALU中还实现了移位操作，实现了算数左移、算数右移、逻辑右移、循环右移；并实现了源操作数的偏移。为了实现唯一操作，ALUControl信号变成三位，第0、1位不变，若第三位为1，则执行移位操作。
- 标志位的生成如ALU。

```verilog
module	ARM_SingleCycle_DataPath  //数据通路模块
	#(parameter	BusWidth = 32)
	(input logic	i_CLK, i_RESET,

	//	Control inputs
	input logic[1:0]                i_Reg_Src,
	input logic[1:0]				i_Imm_Src,
	input logic						i_PC_Src, i_ALU_Src, 
	input logic						i_Mem_ToReg,
	input logic						i_Reg_Write,
	input logic[2:0]				i_ALU_Control,
	//	Control outputs
	output logic[3:0]				o_ALU_Flags,

	//	Memory Control
	input logic[31:0]				i_Instr,
	output logic[(BusWidth - 1):0]	o_PC, o_ALU_Result,

	//	Data WD and RD
	output logic[(BusWidth - 1):0]	o_Write_Data,
	input logic[(BusWidth - 1):0]	i_Read_Data,
	output logic [(BusWidth - 1):0]		s_Reg1_Data, s_Reg2_Data);
```

```verilog
module	ARM_ExtensionUnit  //立即数扩展与移位操作模块
	#(parameter	BusWidth			= 32,
				ExtendableDataWidth	= 24)
	(input logic[(ExtendableDataWidth - 1):0]	i_Data,
	input logic[1:0]							i_ExtensionControl,
	output logic[(BusWidth - 1):0]				o_Extension,
	input logic [31:0] i_Instr);
```

```verilog
module ARM_Shift    //操作数移位模块
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_Data,
	input logic[6:0]				i_Shamt,
	output logic[(BusWidth - 1):0]	o_Shifted_Data);
```

```verilog
module	ARM_ALU     //ALU模块
	#(parameter	BusWidth	= 32,
	parameter ADD = 3'b000,
	parameter SUB = 3'b001,
	parameter AND = 3'b010,
	parameter ORR = 3'b011,
	parameter SHF = 3'b100
    )
	(input logic[(BusWidth - 1):0]	i_ALU_Src1, i_ALU_Src2,
	input logic [31:0]  i_Instr,
	input logic[2:0]				i_ALU_Control,
	output logic[(BusWidth - 1):0]	o_ALU_Result,
	output logic[3:0]				o_ALU_Flags);
```

```verilog
module ARM_Mux2    //多路选通模块
	#(parameter	BusWidth	= 32)
	(input logic[(BusWidth - 1):0]	i_Mux_Src0, i_Mux_Src1,
	input logic [31:0]       i_Instr,
	input logic [2:0]      i_ALU_Control,
	input logic						i_Mux_Src_Select,
	output logic[(BusWidth - 1):0]	o_Mux_out);
```

```verilog
module	ARM_RegisterFile       //存取数操作模块
	#(parameter	BusWidth			= 32,
				RegisterFileSize	= 15)
	(input logic					i_CLK, i_RESET,

	//	Write Control
	input logic						i_Write_Enable,

	//	Register Address inputs
	input logic[3:0]				i_Address_ToRead1, i_Address_ToRead2,
	input logic[3:0]				i_Address_ToWrite,

	//	PC Write input
	input logic[(BusWidth - 1):0]	i_R15,

	//	Data Control
	input logic[(BusWidth - 1):0]	i_Write_Data,
	output logic[(BusWidth - 1):0]	o_Read_Data1, o_Read_Data2);
```

### MCU拓展指令

- 在此次MCU设计中，我们拓展了移位指令。移位指令的实现是在ALU内实现的。我们在控制通路中将ALU控制信号由2位改为了3位，新加的四位用来实现移位指令。在数据通路中，我们实现了LSL、LSR、ASR、ROR指令，其中LSL、LSR、ASR是直接通过计算符“<<”、“>>”、“>>>”实现的，ROR是使用case语句实现的。
- 我们还实现了DATA_PROCESSING中的rot与shamt5的功能。rot是在立即数扩展中实现的，若检测到指令的立即数标志位为1，则在立即数扩展时，将立即数循环右移2×rot位。shamt的实现是通过单独写了一个模块实现的，原理与移位指令类似。

## 五. 具体实现

    在完成可执行具体代码的MCU后，我们需要将指令操作的机器码和数据分别放入ROM和RAM中。由于利用 Block Memory Generator 需要考虑1个或2个时钟周期延迟，为方便指令处理，我们在原MCU的基础使用 Distributed Memory Generator来实现存储器。调用代码如下：

```verilog
dist_mem_gen_1 ROM(
	.a(s_PC[11:2]),
	.we(1'b0),
	.clk(clk_out),
	.d(o_Write_Data),
	.spo(s_Instr)
	);
		
    dist_mem_gen_0 RAM (
  .a(o_Address[16:2]),    
  .d(o_Write_Data),   
  .clk(clk_out),  
  .we(o_Mem_Write),   
  .spo(s_Read_Data)  
);
```

由于ROM和RAM以字节方式寻址，而我们设计了32 bit 的MCU，故在ROM和RAM中传入的地址均需左移两位。

    在存储模块完成后，我们利用 ILA 工具进行了实际上板的测试。

```verilog
ila_0 test (
	.clk(clk_out), // input wire clk

	.probe0(s_PC), // input wire [31:0]  probe0  
	.probe1(o_Write_Data) // input wire [31:0]  probe1
);
```

在附件中的汇编指令中，我们在最后三个指令存在了特定的寄存器中，如果PC和写入RAM中的数据对应且数据正确，则能够说明我们的指令实现正确。

仿真完成后，继续进行了综合布线和生成 bit 流等操作。

## 六. 仿真结果

### 基础指令仿真结果

这里，我们采用了Digital Design and Computer Architecture，ARM® Edition中提供的测试代码。

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled%203.png)

其中机器码如下所示：

```verilog
E04F000F
E2802005
E280300C
E2437009
E1874002
E0035004
E0855004
E0558007
0A00000C
E0538004
AA000000
E2805000
E0578002
B2857001
E0477002
E5837054
E5902060
E08FF000
E280200E
EA000001
E280200D
E280200A
E5802064
```

经计算，原测试代码中要求计算结果为在mem[100]位置中存储数字7，仿真结果如下：

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled%204.png)

符合测试要求。

### LDPC仿真结果

在测试图中，长度为4/6/8的环个数分别为6/5/1，将数据上传到数据RAM中后进行仿真，结果如图所示，探针显示存储的三个数据分别为6/5/1，符合测试要求。

![Untitled](%E6%95%B0%E5%AD%97%E7%94%B5%E8%B7%AF%E8%AF%BE%E7%A8%8B%E8%AE%BE%E8%AE%A1%E6%8A%A5%E5%91%8A%2032936c9010d14e3db9d7c9ce40d195e0/Untitled%205.png)
