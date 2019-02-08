% Kinematische Zwangsbedingungen zwischen Ist- und Soll-Konfiguration
% Vollständige Rotations- und Translationskomponenten
% Variante 1:
% * Vektor vom Basis- zum Koppelpunkt-KS (unterschiedlich zur Variante 1
%   bei seriellen Robotern; dort Basis bis EE)
% * Absolute Rotation ausgedrückt bspw. in XYZ-Euler-Winkeln
%   (statt XYZ wird die Konvention aus `phiconv_W_E` genommen)
% * Rotationsfehler ausgedrückt genauso bspw. in XYZ-Euler-Winkeln
% 
% Eingabe:
% q [Nx1]
%   Alle Gelenkwinkel aller serieller Beinketten der PKM
% xE [6x1]
%   Endeffektorpose des Roboters bezüglich des Basis-KS
% 
% Ausgabe:
% Phi_red
%   Reduzierte kinematische Zwangsbedingungen (siehe folgendes)
%   Die Reduktion folgt aus der Klassenvariablen I_EE
% Phi [6x1]
%   Kinematische Zwangsbedingungen des Roboters: Maß für den Positions- und
%   Orientierungsfehler zwischen Ist-Pose aus gegebenen Gelenkwinkeln q und
%   Soll-Pose aus gegebenen EE-Koordinaten x

% Moritz Schappler, moritz.schappler@imes.uni-hannover.de, 2018-07
% (C) Institut für Mechatronische Systeme, Universität Hannover

function [Phi_red, Phi] = constr1(R, q, xE)

%% Initialisierung
assert(isreal(q) && all(size(q) == [R.NJ 1]), ...
  'ParRob/constr1: q muss %dx1 sein', R.NJ);
assert(isreal(xE) && all(size(xE) == [6 1]), ...
  'ParRob/constr1: xE muss 6x1 sein');

% rotatorischer und translatorischer Teil der ZB
[Phit_red, Phit] = R.constr1_trans(q, xE);
[Phir_red, Phir] = R.constr1_rot(q, xE);

% Anzahl ZB
nPhit = size(Phit_red,1)/R.NLEG;
nPhir = size(Phir_red,1)/R.NLEG;
nPhi = nPhit + nPhir;

% Sortierung der ZB-Zeilen in den Matrizen nach Beingruppen, nicht nach ZB-Art
% Indizierung auch mit Klassenvariablen I_constr_t, I_constr_r, ...
Phi_red = NaN(size(Phit_red,1)+size(Phir_red,1), 1);
Phi =     NaN(size(Phit,1)    +size(Phir ,1),    1);
for i = 1:R.NLEG
  Phi_red((i-1)*nPhi+1:(i)*nPhi, :) = ...
    [Phit_red((i-1)*nPhit+1:(i)*nPhit, :); ...
     Phir_red((i-1)*nPhir+1:(i)*nPhir, :)];
  Phi((i-1)*6+1:(i)*6, :) = ...
    [Phit((i-1)*3+1:(i)*3, :); ...
     Phir((i-1)*3+1:(i)*3, :)];
end
