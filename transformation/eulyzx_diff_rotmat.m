% Ableitung der yzx-Euler-Winkel nach der daraus berechneten Rotationsmatrix
% Konvention: R = roty(phi1) * rotz(phi2) * rotx(phi3).
% (mitgedrehte Euler-Winkel; intrinsisch)
%
% Eingabe:
% R [3x3]:
%   Rotationsmatrix
%
% Ausgabe:
% GradMat [3x9]:
%   Gradientenmatrix: Ableitung der Euler-Winkel nach der (spaltenweise gestapelten) Rotationsmatrix

% Moritz Schappler, moritz.schappler@imes.uni-hannover.de, 2018-10
% (C) Institut für mechatronische Systeme, Leibniz Universität Hannover

function GradMat = eulyzx_diff_rotmat(R)
%% Init
%#codegen
%$cgargs {zeros(3,3)}
assert(isreal(R) && all(size(R) == [3 3]), 'eulyzx_diff_rotmat: R has to be [3x3] (double)');
r11=R(1,1);r12=R(1,2);r13=R(1,3);
r21=R(2,1);r22=R(2,2);r23=R(2,3); %#ok<NASGU>
r31=R(3,1);r32=R(3,2);r33=R(3,3); %#ok<NASGU>
%% Berechnung
% aus codeexport/eulyzx_diff_rotmat_matlab.m (euler_angle_calculations.mw)
t160 = r22 ^ 2 + r23 ^ 2;
t161 = sqrt(t160);
t162 = r21 / t161;
t159 = 0.1e1 / (r11 ^ 2 + r31 ^ 2);
t158 = 0.1e1 / t160;
t1 = [r31 * t159 0 -r11 * t159 0 0 0 0 0 0; 0 t161 0 0 -r22 * t162 0 0 -r23 * t162 0; 0 0 0 0 r23 * t158 0 0 -r22 * t158 0;];
GradMat = t1;
