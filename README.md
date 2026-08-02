# ubuntu-post-install

> [!WARNING]
> Este repo esta siendo modificado para el uso de debian con entorno KDE.

## Descripcion
Estos son archivos de uso personal, puedes copiartelos, descargarlo y mejorarlo a tu gusto. 
Esto esta hecho para facilitar la tarea de instalar y configurar aplicaciones y archivos luego de una reinstalacion o una nueva instalacion.
Puede que no sea lo mas optimo y/o prolijo pero me es util y posiblemente te pueda servir.
Se ira mejorando poco a poco...

Si llegaste a este repo, te invito a que lo uses y lo modifique a tu gusto, no hace falta que lo diga, pero si queres hacer comentarios y subir modificaciones bienvenido sea

## Aplicaciones KDE
- k-programs_core.src
- k-programs.src

Podes agregar y quitar los programas que necesites, en los listados estan los que generalmente uso para mi dia a dia. Solo tenes que asegurarte tener correcto el nombre del paquete, caso contrario te va a fallar

```bash
# en caso de ser necesario, dar permiso de ejecucion al archivo
chmod +x postinstall.sh
# para ejecutarlo:
sudo bash postinstall.sh
```
## Tips adicionales para Debian
agregar al archivo `/etc/apt/source.list` los siguientes sources:
- `contrib`
- `non-free`

> [!NOTE]
> Para mas info ver la [wiki](../../wiki)
