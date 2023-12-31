Граматика для парсингу задач на побудову
В обчисленнях будуть враховані тільки основи слів, токени між словами з граматики будуть пропущені.
Використані позначення:

- круглі дужки визначають порядок виконання
- a | b - граматиці відповідає a або b
- {a} - 'a' може зустрітися нуль або більше разів
- [a] - 'a' може зустрітися один або більше разів
- a? - 'a' може зустрітися нуль або один раз
- '[a-z]' - граматиці відповідають символи від 'a' до 'z' включно
- '\d' - граматиці відповідає будь-яка цифра (0-9)

```text
<роздільник дій> ::= '.'
<роздільник декларацій> ::= ',' | ';'

<координати> ::= '(' ['\d'] ',' ['\d'] ')'
<ідентифікатор:точка> ::= '[A-Z]' <координати>?, // напр. M | M(1,12)
<ідентифікатор:пряма> ::= <ідентифікатор:точка> <ідентифікатор:точка> | '[a-z]'
<ідентифікатор> ::= <ідентифікатор:пряма> | <ідентифікатор:точка>

<тип> ::= 'пряма' | 'точка'
<об'єкт> ::= <тип> { <ідентифікатор> <роздільник декларацій>? } 
                                       // якщо ідентифікатор не заданий, 
                                       // мається на увазі попередній об'єкт цього типу в межах визначення дії, або
                                       // кореневий об'єкт цього типу, якщо таких об'єктів немає
<властивість> ::= ( 'перетинається' | 'паралельна' | 'перпендикулярна' ) <ідентифікатор:пряма>
<декларація> ::= [ ( <об'єкт> <властивість>? ) <роздільник декларацій>? ]
                                       // роздільники мають бути присутні завжди, орім як після 
                                       // останньої декларації, де це не вимагається

<операція> ::= 'побудувати' | 'провести' | 'позначити'
<дія> ::= <операція> [ <декларація> <роздільник декларацій>? ]

<умова> ::= <об'єкт> [ <властивість> <роздільник декларацій>? ]

<задача> ::= [<дії> <роздільник дій>] ( ( 'де' | 'через' ) [ <умова> ] )?
```
