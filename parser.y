%{
	#include <stdio.h>
	#include <string.h>
	#include <vector>
	#include "varint.h"
	long line_counter = 1L;
	short err = 0;
	short debug = 0;
	long block = 0;
	std::vector< VarInt * > BlockList;
%}

%union{
	char* str;
	int integer;
}


%token DEFINE
%token AS
%token BLOCKS
%token VALUE_SENTENCE
%token SET
%token OUT
%token FOR
%token GO
%token <str> BACK
%token <str> STRAIGHT
%token TILL
%token TURN
%token LEFT
%token RIGHT
%token KEEP
%token GOING
%token SKIP
%token KEEPEND
%token FOR_CYCLE
%token TIMES
%token LEFT_SQUARE_BRACKED
%token WALK
%token RIGHT_SQUARE_BRACKED
%token FOREND
%token WHEN
%token THEN
%token WHEND
%token START
%token STOP
%token ON
%token REST
%token <integer> VALUE
%token <str> IDENTIFIER
%token WHITE_SPACE
%token DOTCOMA
%token OPERATOR
%token LEFT_BLOCK_BRACKED
%token RIGHT_BLOCK_BRACKED

%token EQUAL
%token NOT_EQUAL
%token HIGH
%token LESS
%token EQUAL_HIGH
%token EQUAL_LESS
%token PRINT


%type <integer> mathematicExpresion
%type <integer> aValue
%type <str> error

%start initial


%%

initial:
	expresion
	| expresion initial
;

expresion:
    WHEN condition THEN  LEFT_BLOCK_BRACKED initial RIGHT_BLOCK_BRACKED WHEND DOTCOMA {block++;}
    | FOR_CYCLE VALUE TIMES LEFT_SQUARE_BRACKED WALK VALUE IDENTIFIER RIGHT_SQUARE_BRACKED LEFT_BLOCK_BRACKED initial RIGHT_BLOCK_BRACKED FOREND DOTCOMA {block++;printf("For cycle\n");}
    | simple_expresion
;



simple_expresion:
    GO Ydirection TILL IDENTIFIER BLOCKS DOTCOMA {printf("hello %d\n", $4);}
    | GO Ydirection TILL VALUE BLOCKS DOTCOMA {printf("hello %d\n", $4);}
    | GO Ydirection DOTCOMA {printf("hello %s\n", yylval.str);}
    | DEFINE IDENTIFIER AS BLOCKS DOTCOMA {BlockList.push_back(new VarInt($2,strlen($2),block,0));printf("definiendo variable: %s\n", $2);}
    | VALUE_SENTENCE mathematicExpresion SET OUT FOR IDENTIFIER DOTCOMA 
{
for (int i = 0; i < BlockList.size();i++){
	if (strcmp(BlockList.at(i)->getName(), $6) == 0){
		BlockList.back()->setInteger($2);
		printf("el valor de \"%s\" es: %d\n", $6 , $2);
		break;
	}
}

}
    | TURN turndirection DOTCOMA
    | START DOTCOMA
    | STOP DOTCOMA
    | TURN ON DOTCOMA
    | REST FOR aValue DOTCOMA
    | PRINT aValue DOTCOMA { printf("el valor es: %d; \n", $2);}
;

Ydirection:
    STRAIGHT
    | BACK
;

turndirection:
    LEFT
    | RIGHT
    ;

mathematicExpresion:
    aValue {printf("valor = %d \n", $1);$$ = $1;}
    | aValue OPERATOR mathematicExpresion {printf("on operator\n");$$ = $1 + $3;}
;

aValue:
    IDENTIFIER 
{int i = 0; for (; i < BlockList.size();i++){
	if (strcmp(BlockList.at(i)->getName(), $1) == 0){
		$$ = BlockList.back()->getInteger();
		break;
	}
  }
 if (i == BlockList.size()){printf("[error]: La variable \"%s\" no existe, se cerrara el programa!.\n", $1);err= 1;return 0;}
}

    | VALUE	{$$ = $1;}
    ;


condition:
    aValue comparator aValue
    ;


comparator:
    EQUAL
    | NOT_EQUAL
    | HIGH
    | LESS
    | EQUAL_HIGH
    | EQUAL_LESS
;

%%

#include "lex.yy.c"
int main(int argc, char** args){
	if (argc == 3 || argc == 4){
		if (yyin = fopen(args[1],"r")){
			if (argc == 4 && strcmp(args[3],"-d")==0){debug = 1;printf("Debuger encendido\n");}
			else if (argc == 4){
				printf("Error del tercer argumento, solamente se admite \"-d\", sin comillas\n");
				printf("Dicho argumento es para debugear la compilacion\n");
				fclose(yyin);
				return -1;
			}
			yyout = fopen(args[2],"w+");
			yyparse();
			fclose(yyin);
			fclose(yyout);

			if (err){
				remove(args[2]);
				printf("Error de compilacion!\n");
			}else{
				printf("Compilacion terminada con exito!\n");
			}
		}
		else printf("el archivo \"%s\" no existe\n", args[1]);
	}
	else{
		printf("Para compilar debe insertar los argumentos:\n");
		printf("\t1) archivo de entrada\n");
		printf("\t2) archivo de salida\n");
		printf("\t3) -d para debugeo, este argumento es opcional\n");
	}
	return 0;
}
int yyerror(const char* s ) {
	yyerrok;
	fprintf(stderr,"%s: %s at line %ld\n", s, yytext,line_counter);
    	yyclearin;
	err = 1;
//	return err;
}
