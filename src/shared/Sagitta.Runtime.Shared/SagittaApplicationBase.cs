namespace PervasiveDigital.Sagitta.Runtime
{
    using System;
    using System.Collections.Generic;
    using System.Text;

    public abstract class SagittaApplicationBase
    {
        public SagittaApplicationBase()
        {
        }

        public virtual void BeforeDriverInitialization() { }
        public virtual void AfterDriverInitialization() { }
        public virtual void BeforeMiddlewareInitialization() { }
        public virtual void AfterMiddlewareInitialization() { }
        public virtual void BeforeAgentInitialization() { }
        public virtual void AfterAgentInitialization() { }
    }
}
