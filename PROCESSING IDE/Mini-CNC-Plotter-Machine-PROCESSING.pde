import  processing.serial.*; 

PImage  bitmap_image;
String  bitmap_name;            

int     MAX_APPL_WIDTH = 460;    
int     MAX_APPL_HEIGHT = 460;   
int     MAX_PHYSICAL_WIDTH = 114;  
int     MAX_PHYSICAL_HEIGHT = 114; 
int     WHITE_PIXEL_THR = 255;

int     file_size_addr = 2;      
int     width_addr = 18;         
int     height_addr = 22;        

int     depth_color_addr = 28;   
int     offset = 54+1024;       
int     total_size;
int     padding_width;

byte    tx_data [] = new byte[offset + 116*116];

int     low_width;
int     hi_width;
int     low_height;
int     hi_height;
int     low_size;
int     hi_size;

boolean redraw_OpenFile;         
boolean redraw_Resize;           
boolean redraw_ProcedResize;    
boolean redraw_PrintImage;        
boolean opened_image;            
                                 
boolean resized_image;
boolean resize_showed;           
boolean print_showed;           
boolean draw_ResizeControls;    
boolean deny_upsize_width;      
boolean deny_upsize_height;
boolean resizecontrols_showed;
boolean proceedresize_showed;
boolean left_clicked;

boolean deny_resize;
boolean deny_print;

boolean transmission_enable;    
                                
                                
int     new_width;
int     new_height;
int     color_depth;        

int     dec_width;              
int     dec_height;             

String  img_w  = "Image width: ";
String  img_h  = "Image height: ";
String  img_cd = "Number of colors: ";
String  openfile_text = "File Open";
String  imageresize_text = "Resize Image";
String  widthresize_text = "New width: ";
String  heightresize_text = "New height: ";
String  resize_text = "Proceed resize";
String  message_window = " Application status window ";
String  print_text = "Print image";

String  crt_status_msg;           
String  next_status_msg;          

Serial  my_port;
byte    data;
byte    APP_START     = 0;        
                                  
                                  
                                  
                                  

byte    INVALID_LINE  = 3;
byte    VALID_LINE    = 4;
byte    PIXELS_00     = 5;
byte    PIXELS_01     = 6;
byte    PIXELS_10     = 7;
byte    PIXELS_11     = 8;
byte    ARDUINO_READY = 9;
byte    ARDUINO_DONE  = 10;

boolean sending_width;
boolean sending_height;
boolean first_byte;

boolean first_sof_valid_line_byte;
byte    first_pixel_index;        
byte    effective_line_length;    
int     fpindex;
int     ellength;

boolean left_2_right;
boolean start_of_line;
int     r_index;                  
int     c_index;                  
int     actual_w;                 
int     actual_h;
int     read_address;
int     padding_w; 


void setup() { 
  size(930, 710);                 
  
 
  my_port = new Serial(this, "COM4", 9600);
  
  noStroke();                      
  frameRate(10);                  
  textSize(20);                   
  background(0);                  
  
 
  fill(255);                      
  rect(22, 36, 128, 34, 6);
  fill(0);                        
  text(openfile_text, 40, 58);
  
 
  drawAppStatusWindow("");        
  
  resetProgramLogic();
} 
 
void draw() {                     
  redraw_OpenFile = false;
  redraw_Resize = false;
  redraw_PrintImage = false;
  redraw_ProcedResize = false;
  deny_resize = false;
  deny_print = false;
  
  if(mouseOverFileOpen() == true){
    redraw_OpenFile = true;
    if(left_clicked == true){
      selectInput("Select the bitmap file to be sent", "actionOpenFile");
      left_clicked = false;
    }
  }
 
  else if((mouseOverResize() == true) && (resize_showed == true)){  
    redraw_Resize = true;            
    if(left_clicked == true){
      draw_ResizeControls = true;
      resizecontrols_showed = true;
      left_clicked = false;
    }
  }
  else if((mouseOverPrint() == true) && (print_showed == true)){
    redraw_PrintImage = true;
    
    if(left_clicked == true){
      
     
      if(transmission_enable == false){
      
       
        drawAppStatusWindow("Initialising the Printer...");
        
       
        transmission_enable = true;
        
       
        sending_width = true;
        sending_height = false;
        first_byte = false;         
        left_2_right = true;        
        left_clicked = false;
        
       
        my_port.write(0xFF & APP_START);
      }
    }
  }
  else if((mouseOverIncrWidArr() == true) && (resizecontrols_showed == true) && (left_clicked == true)){
    if(deny_upsize_width == false)
      new_width++;
    draw_ResizeControls = true;
    proceedresize_showed = true;
    left_clicked = false;
  }
  else if((mouseOverDecrWidArr() == true) && (resizecontrols_showed == true) && (left_clicked == true)){
    if(new_width > MAX_PHYSICAL_WIDTH)
      dec_width = (new_width - MAX_PHYSICAL_WIDTH)/ 20 + 1;
    else
      dec_width = 1;
    
    new_width -= dec_width;
    draw_ResizeControls = true;
    proceedresize_showed = true;
    left_clicked = false; 
  }
  else if((mouseOverIncrHeiArr() == true) && (resizecontrols_showed == true) && (left_clicked == true)){
    if(deny_upsize_height == false)
      new_height++;
    draw_ResizeControls = true;
    proceedresize_showed = true;
    left_clicked = false; 
  }
  else if((mouseOverDecrHeiArr() == true) && (resizecontrols_showed == true) && (left_clicked == true)){
    if(new_height > MAX_PHYSICAL_HEIGHT)
      dec_height = (new_height - MAX_PHYSICAL_HEIGHT)/ 20 + 1;
    else
      dec_height = 1;
    
    new_height -= dec_height;
    draw_ResizeControls = true;
    proceedresize_showed = true;
    left_clicked = false; 
  }
  else if((mouseOverProcedRes() == true) && (proceedresize_showed == true) && (transmission_enable == false)){
    redraw_ProcedResize = true;
    if(left_clicked == true){
      
     
      bitmap_image.resize(new_width, new_height);
      
     
      bitmap_image.updatePixels();
      
      low_width = new_width % 256;
      hi_width = new_width / 256;
      low_height = new_height % 256;
      hi_height = new_height / 256;
      padding_width = new_width % 4;
      total_size = offset + (new_width + padding_width)*new_height;
      low_size = total_size % 256;
      hi_size = total_size / 256;
      
     
      tx_data[file_size_addr  ] = (byte)low_size;
      tx_data[file_size_addr+1] = (byte)hi_size;
      tx_data[file_size_addr+2] = (byte)0;
      tx_data[file_size_addr+3] = (byte)0;
      
     
      tx_data[width_addr  ] = (byte) low_width;
      tx_data[width_addr+1] = (byte) hi_width;
      tx_data[width_addr+2] = (byte)0;
      tx_data[width_addr+3] = (byte)0;
      
     
      tx_data[height_addr  ] = (byte) low_height;
      tx_data[height_addr+1] = (byte) hi_height;
      tx_data[height_addr+2] = (byte)0;
      tx_data[height_addr+3] = (byte)0;
      
     
      for(int i=0; i<new_height; i++)
        for(int j=0; j<new_width; j++)
          tx_data[offset+i*(new_width+padding_width)+j] = (byte)bitmap_image.pixels[i*new_width+j];
      
     
      resized_image = true;
      left_clicked = false;
    }
  }
  else{
    left_clicked = false;
    
    if(transmission_enable == true){
      if(next_status_msg != crt_status_msg){
        crt_status_msg = next_status_msg;
        drawAppStatusWindow(crt_status_msg);
        if(data == ARDUINO_DONE)
          resetProgramLogic();
      }
    }
  }
    
  redrawOpenFile();
  drawResize();
  drawPrintImage();
  drawResizeControls();
  drawProceedResize();
 
  if((opened_image == true) || (resized_image == true) && (transmission_enable == false)){
    
   
    fill(0);
    rect(16, 92, 914, 480);        
    
    if(checkFileExtension(bitmap_name) == false){            
      drawAppStatusWindow("This application could send only bitmap images to Arduino. \nOpen a bitmap image.");
      
     
      deny_resize = true;
      deny_print = true;
    }
    else{
      
     
      fill(255);                                
      new_width = bitmap_image.width;
      new_height = bitmap_image.height;
      color_depth = (int)pow(2, (tx_data[depth_color_addr] + 256*tx_data[depth_color_addr+1]));
      text(img_w+bitmap_image.width, 510, 114);
      text(img_h+bitmap_image.height, 510, 138);
      text(img_cd+color_depth, 510, 162);
      
      if(bitmap_image.width > MAX_APPL_WIDTH || bitmap_image.height > MAX_APPL_HEIGHT){
        drawAppStatusWindow("Application cannot display images larger than 460 x 460 pixels! \nTry open another image.");
        
       
        deny_resize = true;
        deny_print = true;
      }
      else{
        
       
        image(bitmap_image, 24, 96);
        
       
        stroke(255, 0, 0);    
        strokeWeight(4);
        noFill();
        rect(20, 92, MAX_APPL_WIDTH+8, MAX_APPL_HEIGHT+8);
        noStroke();
        
       
        stroke(0, 85, 255);   
        strokeWeight(4);      
        noFill();
        rect(20, 92, MAX_PHYSICAL_WIDTH+8, MAX_PHYSICAL_WIDTH+8);
        noStroke();
        
        if(bitmap_image.width > MAX_PHYSICAL_WIDTH || bitmap_image.height > MAX_PHYSICAL_HEIGHT){
          
         
          if(bitmap_image.width > MAX_PHYSICAL_WIDTH)
            deny_upsize_width = true;
          if(bitmap_image.height > MAX_PHYSICAL_HEIGHT)
            deny_upsize_height = true;         
          
         
          deny_print = true;
          deny_resize = false;
          drawAppStatusWindow("Opened image size exceeds the maximum physical image size. Downsize the image \nuntil it fits into the blue rectangle then print it or open a smaller image.");
        }
        else{
          deny_upsize_width = false;
          deny_upsize_height = false;
          deny_resize = false;
          deny_print = false;
          drawAppStatusWindow("");              
        }
      }
    }
    
    resize_showed = false;
    print_showed = false;
       
    if(deny_resize == false)
      resize_showed = true;         
    
    if(deny_print == false)
      print_showed = true;          
    
   
    proceedresize_showed = false;
    
   
    opened_image = false;
    resized_image = false;
  }
} 

boolean mouseOverProcedRes(){
  return ((mouseX >= 728) && (mouseX <= 910) && (mouseY >= 250) && (mouseY <= 280));
}

boolean mouseOverIncrWidArr(){
  return ((mouseX >= 710) && (mouseX <= 720) && (mouseY >= 250) && (mouseY <= 260));
}

boolean mouseOverDecrWidArr(){
  return ((mouseX >= 690) && (mouseX <= 700) && (mouseY >= 250) && (mouseY <= 260));
}

boolean mouseOverIncrHeiArr(){
  return ((mouseX >= 710) && (mouseX <= 720) && (mouseY >= 270) && (mouseY <= 280));
}

boolean mouseOverDecrHeiArr(){
  return ((mouseX >= 690) && (mouseX <= 700) && (mouseY >= 270) && (mouseY <= 280));
}

boolean mouseOverFileOpen() { 
  return ((mouseX >= 22) && (mouseX <= 150) && (mouseY >= 36) && (mouseY <= 70)); 
} 

boolean mouseOverResize(){
  return ((mouseX >= 510) && (mouseX <= 680) && (mouseY >= 196) && (mouseY <= 230));
}

boolean mouseOverPrint(){
  return ((mouseX >= 720) && (mouseX <= 870) && (mouseY >= 196) && (mouseY <= 230));
}

void resetProgramLogic(){
  resize_showed = false;
  print_showed = false;
  draw_ResizeControls = false;
  resizecontrols_showed = false;
  proceedresize_showed = false;
  opened_image = false;
  resized_image = false;
  left_clicked = false;
  deny_upsize_width = false;
  deny_upsize_height = false;
  transmission_enable = false;
  start_of_line = false; 
}

void actionOpenFile(File selected_file){                
  bitmap_name = selected_file.getAbsolutePath();
  bitmap_image = loadImage(bitmap_name, "bmp");
 
  byte tmp_data [] = loadBytes(bitmap_name);
  
 
  int padd = bitmap_image.width % 4;
 
  for(int i=0; i<offset; i++)
   
    tx_data[i] = tmp_data[i];
  
  for(int i=0; i<bitmap_image.height; i++)
    for(int j=0; j<bitmap_image.width+padd; j++)
      
       tx_data[offset + i*(bitmap_image.width+padd)+j] = tmp_data[offset + (bitmap_image.height -1 -i)*(bitmap_image.width+padd)+j];
  
 
 
 
  
  opened_image = true;
}

boolean checkFileExtension(String file_path){           
  int path_len = file_path.length();
  return ((file_path.charAt(path_len-3) == 'b') && (file_path.charAt(path_len-2) == 'm') && (file_path.charAt(path_len-1) == 'p'));
}

boolean checkValidLine(){
  boolean valid_l = false;
  int start_index = offset + (r_index * (actual_w + padding_w));
  for(int i=start_index; i<start_index+actual_w; i++){            
    if((0xFF & (byte)tx_data[i]) < WHITE_PIXEL_THR)
      valid_l = true;
  }
  
  return valid_l;
}

byte [] validLineInfo(){
  byte [] line_info = new byte[2];
  int starting_pos;
  int effective_len;
  int start_index = offset + (r_index * (actual_w + padding_w));
  
 
  if(left_2_right == true){
    starting_pos = 0;
    for(int i=start_index; i<start_index+actual_w; i++)
      if((0xFF & (byte)tx_data[i]) == WHITE_PIXEL_THR)
        starting_pos++;
      else
        break;
        
    effective_len = actual_w-1;
    for(int i=start_index+actual_w-1; i>start_index+starting_pos; i--)
      if((0xFF & (byte)tx_data[i]) == WHITE_PIXEL_THR)
        effective_len--;
      else
        break;
        
    line_info[0] = (byte)(starting_pos +12);
    line_info[1] = (byte)(effective_len - starting_pos +1 + 12);
  }
  else{
    starting_pos = actual_w-1;
    for(int i=start_index+actual_w-1; i>=start_index; i--)
      if((0xFF & (byte)tx_data[i]) == WHITE_PIXEL_THR)
        starting_pos--;
      else
        break;
   
    effective_len = 0;
    for(int i=start_index; i<start_index+starting_pos; i++)
      if((0xFF & (byte)tx_data[i]) == WHITE_PIXEL_THR)
        effective_len++;
      else
        break;
        
    line_info[0] = (byte)(starting_pos +12);
    line_info[1] = (byte)(starting_pos - effective_len +1 + 12);
  }
     
  return line_info;
}

byte crtAndNextPixels(boolean last_px_in_line){
  byte crt_and_next_px = PIXELS_00;
  int  crt_addr = read_address;   
  int  next_addr;
  
  if(left_2_right == true)
    next_addr = crt_addr+1;
  else
    next_addr = crt_addr-1;
  
  if(last_px_in_line == false){
    if(((0xFF & (byte)tx_data[crt_addr]) < WHITE_PIXEL_THR) && 
       ((0xFF & (byte)tx_data[next_addr]) < WHITE_PIXEL_THR))
      crt_and_next_px = PIXELS_11;
    else if(((0xFF & (byte)tx_data[crt_addr]) < WHITE_PIXEL_THR) &&
            ((0xFF & (byte)tx_data[next_addr]) == WHITE_PIXEL_THR))
      crt_and_next_px = PIXELS_10;
    else if(((0xFF & (byte)tx_data[crt_addr]) == WHITE_PIXEL_THR) && 
            ((0xFF & (byte)tx_data[next_addr]) < WHITE_PIXEL_THR))
      crt_and_next_px = PIXELS_01;
    else if(((0xFF & (byte)tx_data[crt_addr]) == WHITE_PIXEL_THR) && 
            ((0xFF & (byte)tx_data[next_addr]) == WHITE_PIXEL_THR))
      crt_and_next_px = PIXELS_00;
  }
  else{  
    if((0xFF & (byte)tx_data[crt_addr]) < WHITE_PIXEL_THR)
      crt_and_next_px = PIXELS_10;
    else
      crt_and_next_px = PIXELS_01;
  }
  
  return crt_and_next_px;
}

void mousePressed(){
  if(mouseButton == LEFT)
    left_clicked = true;
}

void drawProceedResize(){
  if(proceedresize_showed == true){
    if(redraw_ProcedResize == true)
      fill(150);
    else
      fill(255);
    rect(728, 250, 182, 34, 6);   
    fill(0);
    text(resize_text, 748, 272);
  }
}

void drawResizeControls(){
  if(draw_ResizeControls == true){
    
   
    fill(0);
    rect(510, 245, 160, 22);
    fill(255);
    
    text(widthresize_text+new_width, 510, 260);
    triangle(700, 248, 700, 258, 690, 253);
    if(deny_upsize_width == false)
      triangle(710, 248, 710, 258, 720, 253);
    
    fill(0);
    rect(510, 268, 160, 24);
    fill(255);
    
    text(heightresize_text+new_height, 510, 282);
    triangle(700, 270, 700, 280, 690, 275);
    if(deny_upsize_height == false)
      triangle(710, 270, 710, 280, 720, 275);
    
    draw_ResizeControls = false;
  }
}

void redrawOpenFile(){
  if(redraw_OpenFile == true)
    fill(150);
  else
    fill(255);                    
  rect(22, 36, 128, 34, 6);       
  fill(0);                        
  text(openfile_text, 40, 58);
}

void drawResize(){                
 
 
 
 
 
  if(resize_showed == true){
    if(redraw_Resize == true)
      fill(150);
    else
      fill(255);                  
    rect(510, 196, 170, 34, 6);   
    fill(0);
    text(imageresize_text, 533, 218);
  }
}

void drawPrintImage(){            
 
 
 
 
  if(print_showed == true){
    if(redraw_PrintImage == true)
      fill(150);
    else
      fill(255);
    rect(720, 196, 150, 34, 6);   
    fill(0);
    text(print_text, 740, 218);
  }
}

void drawAppStatusWindow(String message_to_display){
  
 
  stroke(255);          
  strokeWeight(2);      
  
 
  noFill();
  rect(20, 600, 890, 90);
 
  
 
  fill(0);
  noStroke();
  rect(320, 590, 280, 20);
  textSize(20);
  fill(255);
  text(message_window, 326, 604);
  
 
  fill(254, 254, 250);     
  rect(30, 610, 870, 70);
  
 
  fill(0);
  text(message_to_display, 40, 636);
  noStroke();
}


void serialEvent(Serial my_port){          
  if(my_port.available()!=0){             
    data = (byte)my_port.read();
    
    if(transmission_enable == true){                
        
      if(data == ARDUINO_READY){                       
      
        if(sending_width == true){                       
          println("sending image width...");
          if(first_byte == false){                           
            my_port.write(0xFF & (byte)tx_data[width_addr]);
            first_byte = true;
          }
          else if(first_byte == true){                       
            my_port.write(0xFF & (byte)tx_data[width_addr+1]);
            first_byte = false;
            sending_width = false;
            sending_height = true;
          }
        }
        else if(sending_height == true){                 
          println("sending image height...");
          if(first_byte == false){                           
            my_port.write(0xFF & (byte)tx_data[height_addr]);
            first_byte = true;
          }
          else if(first_byte == true){                       
            my_port.write(0xFF & (byte)tx_data[height_addr+1]);
            sending_height = false;
            next_status_msg = "Initialising the Printer... done. \nPrinting the image...";
            
           
           
            start_of_line = true;
            first_sof_valid_line_byte = false;   
            r_index = 0;               
            c_index = 0;
            actual_w = (0xFF & (byte)tx_data[width_addr]) + 256*(0xFF & (byte)tx_data[width_addr+1]);
            actual_h = (0xFF & (byte)tx_data[height_addr]) + 256*(0xFF & (byte)tx_data[height_addr+1]);
            padding_w = actual_w % 4;
          }
        }
        else{                           
          if(r_index < actual_h){
            
            if(start_of_line == true){
              
             
              if(checkValidLine() == true){
                if(first_sof_valid_line_byte == false){
                  
                 
                  first_pixel_index = validLineInfo()[0];
                  c_index = first_pixel_index -12;            
                                                              
                  fpindex = c_index;
                  print("First pixel index: ");
                  println(c_index);
                  
                  my_port.write(0xFF & first_pixel_index);
                  first_sof_valid_line_byte = true;           
                }
                else if(first_sof_valid_line_byte == true){
                  
                 
                  effective_line_length = validLineInfo()[1]; 
                  ellength = effective_line_length -12;
                  
                  print("Effective line length: ");
                  println((0xFF & effective_line_length) -12);
                  
                  my_port.write(0xFF & effective_line_length);
                  first_sof_valid_line_byte = false;
                  start_of_line = false;
                }
              }
              else{
                my_port.write(0xFF & INVALID_LINE);
                print("invalid line"); println(r_index);
                
               
                r_index++;
                
               
                start_of_line = true;
              }
            }
            else{                       
              if(left_2_right == true){     
               
                if(c_index < fpindex  + ellength ){
                  read_address = offset + (r_index * (actual_w + padding_w)) + c_index;
                  
                  if(c_index == fpindex  + ellength  -1){
                    my_port.write(0xFF & crtAndNextPixels(true));
                   
                  }
                  else{
                    my_port.write(0xFF & crtAndNextPixels(false));
                   
                  }
                   
                  c_index++;
                  
                 
                  
                  if(c_index == fpindex  + ellength ){
        
                    println("");
                    
                   
                    r_index++;
                    
                   
                    start_of_line = true;
                    
                   
                    first_sof_valid_line_byte = false;
                    
                   
                    left_2_right = !left_2_right;
                  }
                }
              }
              else{                           
                
                if(c_index >= fpindex  - ellength  + 1){
                  
                  read_address = offset + (r_index * (actual_w + padding_w)) + c_index;
                  
                  if(c_index == fpindex  - ellength  + 1){
                    my_port.write(0xFF & crtAndNextPixels(true));
                   
                  }
                  else{
                    my_port.write(0xFF & crtAndNextPixels(false));
                   
                  }
                  
                  c_index--;
                  
                  if(c_index == fpindex  - ellength ){
                    
                    println("");
                    
                   
                    r_index++;
                    
                   
                    start_of_line = true;
                    
                   
                    first_sof_valid_line_byte = false;
                    
                   
                    left_2_right = !left_2_right;
                  }
                }
              }
            }
          }
        }
      }
      else if(data == ARDUINO_DONE){       
                                           
        next_status_msg = "Printing the image... done.";
        
        println("done");
        
       
        fill(255);                      
        rect(22, 36, 128, 34, 6);
        fill(0);                        
        text(openfile_text, 40, 58);
      }
    }
  }
}
