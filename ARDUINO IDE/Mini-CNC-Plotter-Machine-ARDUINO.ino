
#include <SD.h>
#include <Servo.h>

#define APPL_START     0 
#define INVALID_LINE   3 
#define VALID_LINE     4   

#define PIXELS_00      5   
#define PIXELS_01      6   
#define PIXELS_10      7   
#define PIXELS_11      8   
#define READY          9   
#define DONE          10   

#define PULSE_WIDTH    10   
#define SERVO_START_ANGLE  98    
#define SERVO_END_ANGLE   115    
#define SERVO_DELAY   50   

#define PIXEL_WIDTH    2   

#define STEPPERS_ENA   8   
#define STEPPER_X_DIR  5   
#define STEPPER_Y_DIR  6   
#define STEPPER_X_DRV  2   
#define STEPPER_Y_DRV  3   
#define X_ZERO_LIMIT   9   
                           
#define Y_ZERO_LIMIT  10   
#define SERVO_DRV     11   


int     awaiting_start;
int     receiving_data;
int     receiving_width;
int     receiving_height;
int     first_byte;         

int     first_sof_byte;    
int     starting_pos;       
int     effective_len;      
int     end_of_line;        

unsigned long width;
unsigned long height;

int     zero_x;
int     zero_y;

int     crt_line;          
int     crt_printed_line;
int     crt_column;        
int     line_printing;     
int     left_2_right_print;
int     ox_sense;
int     delta_y;           
int     delta_x;            
int     pencil_down;       

byte    serial_byte;

Servo   my_servo;

void setup() {
  Serial.begin(9600);

 
  pinMode(STEPPERS_ENA, OUTPUT);
  pinMode(STEPPER_X_DIR, OUTPUT);
  pinMode(STEPPER_X_DRV, OUTPUT);
  pinMode(STEPPER_Y_DIR, OUTPUT);
  pinMode(STEPPER_Y_DRV, OUTPUT);
  pinMode(X_ZERO_LIMIT, INPUT_PULLUP);            
  pinMode(Y_ZERO_LIMIT, INPUT_PULLUP);           

  digitalWrite(STEPPERS_ENA, HIGH);
  digitalWrite(STEPPER_X_DRV, LOW);
  digitalWrite(STEPPER_Y_DRV, LOW);

 
  while(Serial.available()!=0)
    Serial.read();

  awaiting_start = 1;
}

void loop() {
  
}

void makeSteps(int stp_pin, int dir_pin, int sense, int steps_no){
  if(sense == 0)
    digitalWrite(dir_pin, LOW);
  else
    digitalWrite(dir_pin, HIGH);
  for(int i=0; i<steps_no; i++){
    digitalWrite(stp_pin, HIGH);
    delay(PULSE_WIDTH);
    digitalWrite(stp_pin, LOW);
    delay(PULSE_WIDTH);
  }
}

void resetMovingPencil(){
  zero_x = 0;
  zero_y = 0;
  
  while (zero_x == 0 || zero_y == 0){
    if(digitalRead(X_ZERO_LIMIT) == LOW)  
      zero_x = 1;
    else
      makeSteps(STEPPER_X_DRV, STEPPER_X_DIR, 0, PIXEL_WIDTH);  
    
    if(digitalRead(Y_ZERO_LIMIT) == LOW)  
      zero_y = 1;
    else
      makeSteps(STEPPER_Y_DRV, STEPPER_Y_DIR, 0, PIXEL_WIDTH);  
  }
}

byte serialRead(){
  byte serial_data = Serial.read();
  while(Serial.available()!= 0)
    Serial.read();
  return serial_data;
}

void configAtStart(){

 
  receiving_data = 1;

 
  receiving_width = 1;
  first_byte = 1;            
  receiving_height = 0;
  
 
  digitalWrite(STEPPERS_ENA, LOW); 

 
  my_servo.attach(SERVO_DRV);

 
  resetMovingPencil();

 
 
  Serial.write(READY);
  Serial.flush();
}

void receivingBitmapWidth(){

  if(first_byte == 1){
    width = serialRead();
    first_byte = 0;
  }
  else{                                   
    width += 256*serialRead();
    receiving_width = 0;                  
    receiving_height = 1;                 
    first_byte = 1;
  }
  Serial.write(READY);
  Serial.flush();                         
}

void receivingBitmapHeight(){
  
  if(first_byte == 1){                    
    height = serialRead();
    first_byte = 0;
  }
  else{               
    height += 256*serialRead();

   
    receiving_height = 0;

   
    pencil_down = 0;
    my_servo.write(SERVO_START_ANGLE);
    delay(SERVO_DELAY);

   
    crt_line = 0;
    crt_printed_line = 0;

   
    first_sof_byte = 1;

   
    left_2_right_print = 1;

   
    crt_column = 0;

   
    end_of_line = 0;
    line_printing = 0;
  }
  Serial.write(READY);
  Serial.flush();
}

void getLineinfoAndPositionPlatform(){
  
  if(first_sof_byte == 1){
    end_of_line = 0;

   
    starting_pos = serial_byte - 12;

   
   
    delta_x = starting_pos - crt_column;

   
    if(delta_x >=0)
      ox_sense = 1;     
    else{
      ox_sense = 0;     
    }

   
     makeSteps(2, 5, ox_sense, abs(delta_x)*PIXEL_WIDTH);

   
    crt_column = starting_pos;

   
   
    delta_y = crt_line - crt_printed_line;

   
   
    makeSteps(3, 6, 1, delta_y*PIXEL_WIDTH);

   
    first_sof_byte = 0;
  }
  else{
    effective_len = serial_byte - 12;

   
    line_printing = 1;
  }
}

int pixelsToPrint(){
  int there_are_pixels = 0;

  if(((left_2_right_print == 1) && (crt_column < starting_pos+effective_len)) ||
     ((left_2_right_print == 0) && (crt_column > starting_pos-effective_len)))
    there_are_pixels = 1;

  return there_are_pixels;
}

int linePrinted(){
  int line_over = 0;

  if(((left_2_right_print == 1) && (crt_column == starting_pos+effective_len)) ||
     ((left_2_right_print == 0) && (crt_column == starting_pos-effective_len)))
    line_over = 1;

  return line_over;
}

void updateAtEndOfLine(){

 
  crt_printed_line = crt_line;
  
 
  crt_line++;

 
  if(left_2_right_print == 1)    crt_column--;
  else                           crt_column++;
     
  line_printing = 0;
  end_of_line = 1;  

  first_sof_byte = 1;

 
  left_2_right_print = !left_2_right_print;

 
  pencil_down = 0;
  my_servo.write(SERVO_START_ANGLE);
  delay(SERVO_DELAY);
}

void updateAtEndOfBitmap(){

  receiving_data = 0;

  awaiting_start = 1;

 
  pencil_down = 0;
  my_servo.write(SERVO_START_ANGLE); 
  delay(SERVO_DELAY); 
 
 
  my_servo.detach();

 
  digitalWrite(STEPPERS_ENA, HIGH);

 
  Serial.write(DONE);
  Serial.flush();
}

void serialEvent(){
  if(Serial.available()!=0){
    
    if(awaiting_start == 1){              
      if(serialRead() == APPL_START){
        configAtStart();                      
        awaiting_start = 0;             
      }
    }
    else if(receiving_data == 1){           
      
      if(receiving_width == 1)        receivingBitmapWidth();    
      
      else if(receiving_height == 1)  receivingBitmapHeight();   
      
      else if(crt_line < height){              
        
        serial_byte = serialRead();              
        
        if(serial_byte == INVALID_LINE){         
          line_printing = 0;
          end_of_line = 1;
          crt_line++;                               
          first_sof_byte = 1;                             
        }
        else if((serial_byte >= 12) && (line_printing == 0))
          getLineinfoAndPositionPlatform();
        
        else if(line_printing == 1){
            
          if(pixelsToPrint() == 1){
            if(serial_byte == PIXELS_11){   
              if(pencil_down == 0){
                pencil_down = 1;
                
               
                my_servo.write(SERVO_END_ANGLE); 
                delay(SERVO_DELAY);                     
              }
             
            }
            else if(serial_byte == PIXELS_10){ 
              if(pencil_down == 1){                
                pencil_down = 0;
                my_servo.write(SERVO_START_ANGLE);      
                delay(SERVO_DELAY);
              }
              else{                                
                my_servo.write(SERVO_END_ANGLE);        
                delay(SERVO_DELAY);
                my_servo.write(SERVO_START_ANGLE);      
                delay(SERVO_DELAY); 
              }
            }    

           
            if(left_2_right_print == 1)    crt_column++;
            else                           crt_column--;

           
            if(linePrinted() == 1)   
              updateAtEndOfLine();
            else
              makeSteps(2, 5, left_2_right_print, PIXEL_WIDTH);  
          }    
        }

       
        if(!((crt_line == height) && (end_of_line == 1))){
          Serial.write(READY);
          Serial.flush();
        }
        else
          updateAtEndOfBitmap();
      }
    }
  }
}
