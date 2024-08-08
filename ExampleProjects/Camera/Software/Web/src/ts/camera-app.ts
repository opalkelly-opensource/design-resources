import * as frontpanelWs from '@opalkelly/frontpanel-ws';
import 'bootstrap';
import $ from 'jquery';
import svg4everybody from 'svg4everybody';

const SPINNER_SHOW_DELAY = 500; // 0.5 sec.

// By default, bindXXX() functions using this interface show a spinner while
// the action is being executed, but you can explicitly pass
// { withoutSpinner: true } to prevent the spinner from being used.
interface IBindControlHandlerOptions {
    withoutSpinner?: boolean;
    keepPreviousEventHandlers?: boolean;
}

interface IBindClickButtonOptions extends IBindControlHandlerOptions {
    disabledWhileHandling?: boolean;
}

export class CameraApp extends frontpanelWs.FrontPanelWebAppBase {
    public onError?: (e: any) => Promise<void>;

    constructor() {
        super();

        // Support SVG sprites in IE11.
        svg4everybody();

        $(window).on('error', (evt: any) => {
            this.log('Run-time error: ' + JSON.stringify(evt));
            return false;
        });

        // Toggle visibility of controls
        $('#buttonControls').on('click', () => {
            $('#controls').toggleClass('in');
        });

        // Toggle log
        $('[data-toggle="log"]').on('click', () => {
            $('#log').toggleClass('log-expanded');
        });

        // Toggle log on session pages
        const logSwitch = $('#logSwitch');
        logSwitch.on('click', () => {
            $('#log').toggleClass('log-switch-expanded');
            logSwitch.toggleClass('log-switch-active');
            return false;
        });
    }

    public enableControl(name: string): void {
        $(name).prop('disabled', false);
    }

    public disableControl(name: string): void {
        $(name).prop('disabled', true);
    }

    public enableButton(name: string): void {
        $(name)
            .prop('disabled', false)
            .removeClass('button-disabled');
    }

    public disableButton(name: string): void {
        $(name)
            .prop('disabled', true)
            .addClass('button-disabled');
    }

    public bindClickButton(
        name: string,
        onclick: () => Promise<void>,
        options?: IBindClickButtonOptions
    ): void {
        const disabledWhileHandling = options?.disabledWhileHandling;
        const button = $(name);
        if (!options?.keepPreviousEventHandlers) {
            button.off('click');
        }
        button.on('click', async () => {
            if (disabledWhileHandling) {
                this.disableButton(name);
            }

            await this._callWithOptionsAndCheckErrors(onclick, options);

            if (disabledWhileHandling) {
                this.enableButton(name);
            }
            return false;
        });
    }

    public bindChange(
        control: string,
        onchange: () => Promise<void>,
        options?: IBindControlHandlerOptions
    ) {
        const controlElement = $(control);
        if (!options?.keepPreviousEventHandlers) {
            controlElement.off('change');
        }
        controlElement.on('change', async () => {
            await this._callWithOptionsAndCheckErrors(onchange, options);
        });
    }

    public bindSubmit(
        form: string,
        onsubmit: () => Promise<void>,
        options?: IBindControlHandlerOptions
    ) {
        const formElement = $(form);
        if (!options?.keepPreviousEventHandlers) {
            formElement.off('submit');
        }
        formElement.on('submit', async event => {
            event.preventDefault();
            await this._callWithOptionsAndCheckErrors(onsubmit, options);
            return false;
        });
    }

    public startSpinner(): number {
        return window.setTimeout(() => {
            $('#spinnerCamera').show();
        }, SPINNER_SHOW_DELAY);
    }

    public stopSpinner(timer: number): void {
        window.clearTimeout(timer);
        $('#spinnerCamera').hide();
    }

    public async callWithSpinnerAndCheckErrors(
        func: () => Promise<void>
    ): Promise<void> {
        return this._callWithOptionsAndCheckErrors(func, {
            withoutSpinner: false
        });
    }

    public log(text: string): void {
        $('.log-content-main')
            .append(document.createTextNode(text))
            .append(document.createElement('br'));
    }

    protected _callWithOptionsAndCheckErrors(
        func: () => Promise<void>,
        options?: IBindControlHandlerOptions
    ): Promise<void> {
        return this.callAndCheckErrors(async () => {
            let spinner: number | undefined;
            if (!options?.withoutSpinner) {
                spinner = this.startSpinner();
            }
            try {
                await func();
            } finally {
                if (spinner !== undefined) {
                    this.stopSpinner(spinner);
                }
            }
        });
    }

    protected _processError(e: any): void {
        this.onError?.(e);
    }

    protected async _updateConnectionStatus(): Promise<void> {
        // All other GUI elements handled in onConnect() and onDisconnect().
        $('#connectionStatus').text(
            this.isConnected ? `${this.server}` : 'Disconnected'
        );
        if (this.isConnected) {
            $('#imgConnected').show();
            $('#imgDisconnected').hide();
        } else {
            $('#imgConnected').hide();
            $('#imgDisconnected').show();
        }
    }
}
