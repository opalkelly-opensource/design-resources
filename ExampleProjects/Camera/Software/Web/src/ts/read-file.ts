import $ from 'jquery';
import { CameraApp } from './camera-app';

export async function readBinaryFile(
    app: CameraApp,
    title: string,
    hint: string,
    action: string,
    fileSelectedCallback: (filename: string) => void
): Promise<Uint8Array> {
    _prepareToReadFile(app, title, hint, action, fileSelectedCallback);
    const fileReader = await _doReadFileOnClick(
        app,
        (reader: FileReader, blob: Blob) => {
            reader.readAsArrayBuffer(blob);
        }
    );
    return new Uint8Array(fileReader.result as ArrayBuffer);
}

export async function readTextFile(
    app: CameraApp,
    title: string,
    hint: string,
    action: string,
    fileSelectedCallback: (filename: string) => void
): Promise<string> {
    _prepareToReadFile(app, title, hint, action, fileSelectedCallback);
    const fileReader = await _doReadFileOnClick(
        app,
        (reader: FileReader, blob: Blob) => {
            reader.readAsText(blob);
        }
    );
    return fileReader.result as string;
}

function _prepareToReadFile(
    app: CameraApp,
    title: string,
    hint: string,
    action: string,
    fileSelectedCallback: (filename: string) => void
): void {
    $('#titleAddFile').text(title);
    $('#hintAddFile')
        .show()
        .text(hint);
    $('#buttonAddFile')
        .addClass('button-disabled')
        .prop('disabled', true)
        .text(action);
    ($('#formAddFile')[0] as HTMLFormElement)?.reset();
    $('#fileGroup').show();
    $('#fileSelected').hide();
    $('#dialogAddFile').show();
    app.bindChange(
        '#file',
        async () => {
            const file = _getFirstFile();
            $('#hintAddFile').hide();
            $('#fileName').text(file.name);
            $('#fileGroup').hide();
            $('#fileSelected').show();
            $('#buttonAddFile')
                .removeClass('button-disabled')
                .prop('disabled', false);
            fileSelectedCallback(file.name);
        },
        { withoutSpinner: true }
    );
}

function _doReadFileOnClick(
    app: CameraApp,
    readFunc: (reader: FileReader, blob: Blob) => void
): Promise<FileReader> {
    return new Promise<FileReader>((resolve, reject) => {
        app.bindClickButton(
            '#buttonAddFile',
            async () => {
                $('#dialogAddFile').hide();
                const reader = new FileReader();
                reader.onload = () => {
                    resolve(reader);
                };
                reader.onerror = () => {
                    reject(reader.error);
                };
                const file = _getFirstFile();
                readFunc(reader, file as Blob);
            },
            { withoutSpinner: true }
        );
    });
}

function _getFirstFile(): File {
    const fileElement = document.getElementById('file') as HTMLInputElement;
    if (fileElement === null) {
        throw new Error('`file` element not found');
    }
    const file = fileElement.files?.[0];
    if (file === undefined) {
        throw new Error('A file is not selected in `file` input control');
    }
    return file;
}
