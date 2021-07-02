#include <stdio.h>
#include <stdlib.h>

void multiFunction();
void divFunction();
void powFunction();
void rootFunction();

int operationIndicator = 0;

int main() {
printf("-------------------------------------\n");
printf("Computer Architecture 2 - Project\nMiroslaw Kuzniar | Tomasz Grochowski\nAcademic year 2019/2020\n");
printf("-------------------------------------\n");
printf("CALCULATOR\n");
printf(" 1. Multiplication\n 2. Division \n 3. Power\n 4. Square root\n 5. Exit\n");
printf("-------------------------------\n");
printf("Choose operation: ");

scanf("%d", &operationIndicator);
printf("-------------------------------\n");

  switch (operationIndicator) {
    case 1:
      multiFunction();
      break;
    case 2:
      divFunction();
      break;
    case 3:
      powFunction();
      break;
    case 4:
      rootFunction();
      break;
    case 5:
      exit(0);
      break;
  }


return 0;
}
