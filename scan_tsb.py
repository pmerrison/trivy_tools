import argparse
import subprocess
import time

def main():
    argParser = argparse.ArgumentParser()
    argParser.add_argument("-i", "--input", help="The text file containing the list of images to scan") 
    argParser.add_argument("-o", "--output", help="Where to write the results to")
    argParser.add_argument("-p", "--prod-images-only", help="If set, only production images get scanned (demo images are excluded)", type=bool)
    
    args = argParser.parse_args()
    print("args.input=%s" % args.input)

    output_content = []

    demo_images = ["elasticsearch", "postgres", "redis", "tetrate-openldap"]

    timestr = time.strftime("%Y%m%d-%H%M%S")

    print("Scanning images")

    with open(args.input) as image_list_file:
        for line in image_list_file:
            # Since we're copying tctl output, we need to clean up the extraneouse` - `
            clean_line = line.lstrip()
            clean_line = clean_line.strip("-")
            clean_line = clean_line.lstrip()
            clean_line = clean_line.strip() #And remove the trailing newline

            # Check if this is a demo image
            is_demo_image = False
            if(args.prod_images_only == True):
                for demo_image in demo_images:
                    if demo_image in line:
                        is_demo_image = True
                if is_demo_image == True:
                    output_content.append("Skipping "+line+" since it's a demo image\n\n")
                    continue
            
            # Spawn a Trivy process to scan the image
            process = subprocess.Popen(["trivy", "image", clean_line], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = process.communicate()
            rc = process.returncode
            if rc == 0:
                raw_output = stdout.decode('utf-8')
                print(clean_line)
                output_content.append(clean_line)
                print(raw_output)
                output_content.append(raw_output)
                output_content.append('\n')
            else:
                print("Error scanning container "+clean_line)
                print("Stderr: "+stderr.decode("utf-8"))
                output_content.append(clean_line)
                output_content.append(stderr.decode("utf-8"))
                output_content.append('\n')

    output_file_name = args.output+"-"+timestr+".txt"

    print("Writing to file "+output_file_name)

    output_file = open(output_file_name, "w")
    for line in output_content:
        output_file.write(line)
    output_file.close()


if __name__ == "__main__":
    main()
    