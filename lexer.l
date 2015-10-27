%{

#include "y.tab.h"
short exist_table_name = 0;
short exist_column_name = 0;
extern long line_counter;

%}

create	(create|CREATE)
columnModifier (NULL|NOT\ NULL|DEFAULT\ VALUE|null|not\ null|default\ value)
datatype (int|double|date|string|long|short|INT|DOUBLE|DATE|STRING|LONG|SHORT)
identifierAux [A-Za-z_]
identifier	{identifierAux}[A-Za-z_0-9]*
whitespace [ \t\r\n]+
end	\;
leftparentesis \(
rightparentesis \)
coma \,

%%

{create}	{
		printf(">>Se esta compilando la entrada create\n");
		fputc('<',yyout);
		fputs("table name=",yyout);
		return CREATE;
		}

{datatype}	{
		printf("compilando el tipo de dato: %s\n", yytext);
		fputs("type=\"",yyout);
		fputs(yytext, yyout);
		fputs("\" ",yyout);
		return DATATYPE;
		}

{columnModifier} {
		printf("compilando el modificador: %s\n", yytext);
		fputs("modifier=\"",yyout);
		fputs(yytext,yyout);
		fputs("\"/>\n",yyout);
		return COLUMN_MODIFIER;
		}

{identifier}	{
		if (!exist_table_name){
			printf("compilando tabla: %s chars %d\n", yytext, yyleng);
			fputs("\"",yyout);
			fputs(yytext,yyout);
			fputs("\">\n",yyout);
			exist_table_name = 1;
			char *table_name = (char*)malloc(sizeof(char)*yyleng + sizeof(char));
			memcpy(table_name, yytext, yyleng);
			table_name[sizeof(char)*yyleng] = '\0';
			for (int i = 0; i < tablasExistentes.size();i++){
				if (strcmp(tablasExistentes.at(i), table_name) == 0){
					printf("La tabla \"%s\" ya existe, la compilacion se aborata\n", table_name);
					return 0;
				}
			}
			tablasExistentes.push_back(table_name);
		}
		else{
			printf("compilando columna: %s\n", yytext);
			fputs("\t<column name=\"",yyout);
                        fputs(yytext,yyout);
			fputs("\" ", yyout);
			char *column_name = (char*)malloc(sizeof(char)*yyleng + sizeof(char));
                        memcpy(column_name, yytext, yyleng);
                        column_name[sizeof(char)*yyleng] = '\0';
                        for (int i = 0; i < columnasExistentes.size();i++){
                                if (strcmp(columnasExistentes.at(i), column_name) == 0){
                                        printf("La columna \"%s\" ya existe en la tabla %s, la compilacion se aborata\n", column_name, tablasExistentes.back());
                                        return 0;
                                }
                        }
			columnasExistentes.push_back(column_name);

		}
		return IDENTIFIER;
		}

{end}		{
		return DOTCOMA;
		}

{leftparentesis}	{return PARENTESIS_IZQUIERDO;}

{rightparentesis}	{
			printf("se ha terminado la compilacion de la tabla\n");
			exist_table_name = exist_column_name= 0;
			fputs("</table>\n",yyout);
			while(!columnasExistentes.empty()){
				free(columnasExistentes.back());
				columnasExistentes.pop_back();
			}
			printf("el largo es de %d \n", columnasExistentes.size());
			return PARENTESIS_DERECHO;
			}

{coma}		{return COMA;}

{whitespace}	{
		if (yytext[0] == '\n'){
			line_counter++;
		}
		}
		

.	{return 0;}
%%

int yywrap() { return 1; }