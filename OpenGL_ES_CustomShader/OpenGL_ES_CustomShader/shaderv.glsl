attribute vec4 position;
attribute vec4 positionColor;

uniform mat4 projecttionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec4 veryColor;
void main(){
    veryColor = positionColor;
    
    vec4 vPos;
    
    vPos = projecttionMatrix * modelViewMatrix * position;
    
    gl_Position = vPos;
}
