#import <Foundation/Foundation.h>
#import "jpeglib.h"


int main(int argc, char *argv[]) {
	
	@autoreleasepool {
		
		FILE *fp = fopen("../00259.jpg","rb");
		if(fp==NULL) {
			NSLog(@"error : read");
			return 0;
		}

		struct jpeg_error_mgr jerr;
		
		struct jpeg_decompress_struct dinfo;
		jpeg_create_decompress(&dinfo);
		dinfo.err = jpeg_std_error(&jerr);
	
		jpeg_save_markers(&dinfo,JPEG_APP0+3,0xFFFF);
		jpeg_save_markers(&dinfo,JPEG_APP0+4,0xFFFF);
		jpeg_save_markers(&dinfo,JPEG_APP0+5,0xFFFF);
		jpeg_save_markers(&dinfo,JPEG_APP0+6,0xFFFF);
		jpeg_save_markers(&dinfo,JPEG_APP0+7,0x1);
		
		jpeg_stdio_src(&dinfo,fp);
		jpeg_read_header(&dinfo,true);	
		
		int width  = dinfo.image_width;
		int height = dinfo.image_height;
		int bpp = dinfo.num_components;

		NSLog(@"width=%d, height=%d, bpp=%d",width,height,bpp);

		if(!(width==1920&&height==1088&&bpp==3)) {
			NSLog(@"error : format");
			return 0;
		}
		
		unsigned char *df = nullptr;
		if(df==nullptr) {
			df = new unsigned char[(width*height)>>3];
		} 
		
		unsigned char *APP3 = nullptr;
		unsigned char *APP4 = nullptr;
		char *APP5 = nullptr;
		char *APP6 = nullptr;
		char APP7 = -1;
			
		int err = 1<<6|1<<5|1<<4|1<<3;
			
		jpeg_saved_marker_ptr cmarker = dinfo.marker_list;
		while(cmarker) {
			
			if(cmarker->marker==JPEG_APP0+3) {				
				if((width*height)>>9==cmarker->data_length) {
					err ^= 1<<3;
					APP3 = cmarker->data;
				}
				else {
					err |= 1<<3;
				}
			}	
			else if(cmarker->marker==JPEG_APP0+4) {
				if((width*height)>>7==cmarker->data_length) {
					err ^= 1<<4;
					APP4 = cmarker->data;
				}
				else {
					err |= 1<<4;
				}
			}	
			else if(cmarker->marker==JPEG_APP0+5) {
				if((width*height)>>6==cmarker->data_length) {
					err ^= 1<<5;
					APP5 = (char *)cmarker->data;
				}
				else {
					err |= 1<<5;
				}
			}	
			else if(cmarker->marker==JPEG_APP0+6) {
				if((width*height)>>6==cmarker->data_length) {
					err ^= 1<<6;
					APP6 =  (char *)cmarker->data;
				}
				else {
					err |= 1<<6;
				}
			}	
			else if(cmarker->marker==JPEG_APP0+7) {
				if(cmarker->data_length==1) {
					APP7 = *cmarker->data;
				}
			}			
			
			cmarker=cmarker->next;
			
		}
		
		if(err) {
			for(int i=3; i<7; i++) {
				if((err>>i)&1) NSLog(@"error : APP%d",i);
			}			
			return 0;
		}
		
		if((((unsigned char)APP7)>>7)&1) {
			NSLog(@"error : APP7");
		}
		
		jpeg_start_decompress(&dinfo);
			
		if(width==dinfo.output_width&&height==dinfo.output_height&&bpp==dinfo.num_components) {
			
			unsigned char *img = new unsigned char[width*height*bpp];
					
			while(dinfo.output_scanline<height) {
				unsigned char *rowptr = img+dinfo.output_scanline*(width*bpp);
				jpeg_read_scanlines(&dinfo,&rowptr,1);
			}
		
			jpeg_finish_decompress(&dinfo);
			jpeg_destroy_decompress(&dinfo);
			fclose(fp);
			
			delete[] img;
			
		}
		else {
			
			NSLog(@"error : decode");
			
			jpeg_destroy_decompress(&dinfo);
			fclose(fp);
			
		}		
	}
}